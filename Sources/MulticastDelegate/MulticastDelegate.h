//
//  MulticastDelegate.h
//  MulticastDelegate
//
//  Created by kemchenj on 2021/10/17.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface MulticastDelegate<Delegate> : NSObject

@property(nonatomic, weak) __nullable Delegate mainDelegate;
@property(nonatomic, strong) NSHashTable<Delegate> *delegates;

- (void)addDelegate:(Delegate)delegate
       shouldRetain:(BOOL)shouldRetain
    NS_SWIFT_NAME(addDelegate(_:shouldRetain:));
- (void)removeDelegate:(Delegate)delegate;
- (BOOL)voidDelegateMethodsContain:(SEL)selector;

@end

NS_ASSUME_NONNULL_END
