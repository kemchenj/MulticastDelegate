//
//  MulticastDelegate.m
//  MulticastDelegate
//
//  Created by kemchenj on 2021/10/11.
//
//  Inspired by RxCocoa's DelegateProxy. Most code in this file were copied from RxCocoa:
//
//  - https://github.com/ReactiveX/RxSwift/blob/6.2.0/RxCocoa/Common/DelegateProxy.swift
//  - https://github.com/ReactiveX/RxSwift/blob/6.2.0/RxCocoa/Runtime/_RXDelegateProxy.m
//  - https://github.com/ReactiveX/RxSwift/blob/6.2.0/RxCocoa/Runtime/_RXObjCRuntime.m

@import ObjectiveC;
#import "MulticastDelegate.h"

static NSMutableDictionary *voidSelectorsPerClass = nil;

#define SEL_VALUE(x)   [NSValue valueWithPointer:(x)]
#define CLASS_VALUE(x) [NSValue valueWithNonretainedObject:(x)]

BOOL is_method_with_description_void(struct objc_method_description method) {
    return strncmp(method.types, @encode(void), 1) == 0;
}

BOOL is_method_signature_void(NSMethodSignature * __nonnull methodSignature) {
    const char *methodReturnType = methodSignature.methodReturnType;
    return strcmp(methodReturnType, @encode(void)) == 0;
}

@interface MulticastDelegate ()
@property(nonatomic, retain) NSMutableSet *retainDelegates;
@end

@implementation MulticastDelegate

+ (void)initialize {
    @synchronized (MulticastDelegate.class) {
        if (voidSelectorsPerClass == nil) {
            voidSelectorsPerClass = [NSMutableDictionary new];
        }

        NSMutableSet *voidSelectors = [NSMutableSet new];

#define CLASS_HIERARCHY_MAX_DEPTH 100

        NSInteger  classHierarchyDepth = 0;
        Class      targetClass         = NULL;

        for (classHierarchyDepth = 0, targetClass = self;
             classHierarchyDepth < CLASS_HIERARCHY_MAX_DEPTH && targetClass != nil;
             ++classHierarchyDepth, targetClass = class_getSuperclass(targetClass)
        ) {
            unsigned int count;
            Protocol *__unsafe_unretained *pProtocols = class_copyProtocolList(targetClass, &count);

            for (unsigned int i = 0; i < count; i++) {
                NSSet *selectorsForProtocol = [self collectVoidSelectorsForProtocol:pProtocols[i]];
                [voidSelectors unionSet:selectorsForProtocol];
            }

            free(pProtocols);
        }

        if (classHierarchyDepth == CLASS_HIERARCHY_MAX_DEPTH) {
            NSLog(@"Detected weird class hierarchy with depth over %d. Starting with this class -> %@", CLASS_HIERARCHY_MAX_DEPTH, self);
#if DEBUG
            abort();
#endif
        }

        voidSelectorsPerClass[CLASS_VALUE(self)] = voidSelectors;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.retainDelegates = [NSMutableSet new];
        self.delegates = [NSHashTable weakObjectsHashTable];
    }
    return self;
}

- (void)addDelegate:(id)delegate shouldRetain:(BOOL)shouldRetain {
    if (shouldRetain) {
        [self.retainDelegates addObject:delegate];
    }
    [self.delegates addObject:delegate];
}

- (void)removeDelegate:(id)delegate {
    [self.delegates removeObject:delegate];
    [self.retainDelegates removeObject:delegate];
}

- (BOOL)voidDelegateMethodsContain:(SEL)selector {
    @synchronized(MulticastDelegate.class) {
        NSSet *voidSelectors = voidSelectorsPerClass[CLASS_VALUE(self.class)];
        NSAssert(voidSelectors != nil, @"Set of allowed methods not initialized");
        return [voidSelectors containsObject:SEL_VALUE(selector)];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [super respondsToSelector:aSelector]
        || [self.mainDelegate respondsToSelector:aSelector]
        || [self voidDelegateMethodsContain:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    BOOL isVoid = is_method_signature_void(anInvocation.methodSignature);
    if (isVoid) {
        [self voidDelegateMethodInvoked:anInvocation];
    }

    if ([self.mainDelegate respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.mainDelegate];
    }

    if (!isVoid) {
        [super forwardInvocation:anInvocation];
    }
}

- (void)voidDelegateMethodInvoked:(NSInvocation *)invocation {
    for (id delegate in self.delegates) {
        if ([delegate respondsToSelector:invocation.selector]) {
            [invocation invokeWithTarget:delegate];
        }
    }
}

+ (NSSet*)collectVoidSelectorsForProtocol:(Protocol *)protocol {
    NSMutableSet *selectors = [NSMutableSet new];

    unsigned int protocolMethodCount = 0;
    struct objc_method_description *pMethods =
        protocol_copyMethodDescriptionList(protocol, NO, YES, &protocolMethodCount);

    for (unsigned int i = 0; i < protocolMethodCount; ++i) {
        struct objc_method_description method = pMethods[i];
        if (is_method_with_description_void(method)) {
            [selectors addObject:SEL_VALUE(method.name)];
        }
    }

    free(pMethods);

    unsigned int numberOfBaseProtocols = 0;
    Protocol * __unsafe_unretained * pSubprotocols =
        protocol_copyProtocolList(protocol, &numberOfBaseProtocols);

    for (unsigned int i = 0; i < numberOfBaseProtocols; ++i) {
        [selectors unionSet:[self collectVoidSelectorsForProtocol:pSubprotocols[i]]];
    }

    free(pSubprotocols);

    return selectors;
}

@end
