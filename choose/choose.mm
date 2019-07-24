//
//  choose.m
//  choose
//
//  Created by didi on 2019/7/20.
//  Copyright © 2019 didi. All rights reserved.
//
#import "choose.h"

#include <objc/runtime.h>
#include <malloc/malloc.h>
#include <mach/mach.h>
#include <set>

struct choice {
    std::set<Class> query_;
    std::set<id> result_;
};

struct ObjectStruct {
    Class isa_;
};

static kern_return_t read_memory(task_t task, vm_address_t address, vm_size_t size, void **data) {
    *data = reinterpret_cast<void *>(address);
    return KERN_SUCCESS;
}

static Class * copy_class_list(size_t &size) {
    size = objc_getClassList(NULL, 0);
    Class * data = reinterpret_cast<Class *>(malloc(sizeof(Class) * size));
    for (;;) {
        size_t writ = objc_getClassList(data, (int)size);
        if (writ <= size) {
            size = writ;
            return data;
        }
        
        Class * copy = reinterpret_cast<Class *>(realloc(data, sizeof(Class) * writ));
        if (copy == NULL) {
            free(data);
            return NULL;
        }
        data = copy;
        size = writ;
    }
}

static void choose_(task_t task, void *baton, unsigned type, vm_range_t *ranges, unsigned count) {
    choice * choice = reinterpret_cast<struct choice *>(baton);
    for (unsigned i = 0; i < count; ++i) {
        vm_range_t &range = ranges[i];
        void * data = reinterpret_cast<void *>(range.address);
        size_t size = range.size;
        if (size < sizeof(ObjectStruct))
            continue;
        
        uintptr_t * pointers = reinterpret_cast<uintptr_t *>(data);
#ifdef __arm64__
        Class isa = reinterpret_cast<Class>(pointers[0] & 0x1fffffff8);
#else
        Class isa = reinterpret_cast<Class>(pointers[0]);
#endif
        std::set<Class>::const_iterator result(choice->query_.find(isa));
        if (result == choice->query_.end())
            continue;
        size_t needed = class_getInstanceSize(*result);
        size_t boundary = 496;
#ifdef __LP64__
        boundary *= 2;
#endif
        if ((needed <= boundary && (needed + 15) / 16 * 16 != size) || (needed > boundary && (needed + 511) / 512 * 512 != size))
            continue;
        choice->result_.insert(reinterpret_cast<id>(data));
    }
}

@implementation choose

+ (NSArray *)choose:(NSString *)className{
    vm_address_t * zones = NULL;
    unsigned size = 0;
    kern_return_t error = malloc_get_all_zones(0, &read_memory, &zones, &size);
    assert(error == KERN_SUCCESS);
    
    size_t number;
    Class * classes = copy_class_list(number);
    assert(classes != NULL);
    
    choice choice;
    Class _class = NSClassFromString(className);
    for (size_t i = 0; i != number; ++i) {
        for (Class current = classes[i]; current != Nil; current = class_getSuperclass(current)) {
            if (current == _class) {
                choice.query_.insert(classes[i]);
                break;
            }
        }
    }
    free(classes);
    
    for (unsigned i = 0; i != size; ++i) {
        const malloc_zone_t * zone = reinterpret_cast<const malloc_zone_t *>(zones[i]);
        if (zone == NULL || zone->introspect == NULL)
            continue;
        zone->introspect->enumerator(mach_task_self(), &choice, MALLOC_PTR_IN_USE_RANGE_TYPE, zones[i], &read_memory, &choose_);
    }
    
#if __has_feature(objc_arc)
    NSMutableArray * result = [[NSMutableArray alloc] init];
#else
    NSMutableArray * result = [[[NSMutableArray alloc] init] autorelease];
#endif
    for (auto iter = choice.result_.begin(); iter != choice.result_.end(); iter++) {
        [result addObject:(id)*iter];
    }
    return result;
}
@end
