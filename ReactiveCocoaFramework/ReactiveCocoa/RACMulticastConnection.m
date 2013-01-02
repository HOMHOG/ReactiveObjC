//
//  RACMulticastConnection.m
//  ReactiveCocoa
//
//  Created by Josh Abernathy on 4/11/12.
//  Copyright (c) 2012 GitHub, Inc. All rights reserved.
//

#import "RACMulticastConnection.h"
#import "RACMulticastConnection+Private.h"
#import "RACSubject.h"
#import "RACCompoundDisposable.h"
#import "RACSignal+Private.h"

@interface RACMulticastConnection () {
	RACSubject *_signal;
}

@property (nonatomic, readonly, strong) RACSignal *sourceSignal;
@property (nonatomic, readonly, strong) RACCompoundDisposable *disposable;
@property (nonatomic, assign) BOOL hasConnected;
@end

@implementation RACMulticastConnection

#pragma mark Lifecycle

- (id)initWithSourceSignal:(RACSignal *)source subject:(RACSubject *)subject {
	NSParameterAssert(source != nil);
	NSParameterAssert(subject != nil);

	self = [super init];
	if (self == nil) return nil;

	_disposable = [RACCompoundDisposable compoundDisposable];
	_sourceSignal = source;
	_signal = subject;
	
	return self;
}

#pragma mark Connecting

- (RACDisposable *)connect {
	@synchronized(self) {
		if (!self.hasConnected) {
			self.hasConnected = YES;
			
			RACDisposable *sourceDisposable = [self.sourceSignal subscribe:_signal];
			if (sourceDisposable != nil) [self.disposable addDisposable:sourceDisposable];
		}
		
		return self.disposable;
	}
}

- (RACSignal *)autoconnect {
	return [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
		RACDisposable *subscriptionDisposable = [self.signal subscribe:subscriber];
		if (subscriptionDisposable != nil) [self.disposable addDisposable:subscriptionDisposable];
		[self connect];

		return [RACDisposable disposableWithBlock:^{
			[subscriptionDisposable dispose];
			
			@synchronized(self.signal.subscribers) {
				if (self.signal.subscribers.count < 1) {
					[self.disposable dispose];
				}
			}
		}];
	} name:@"[%@] -autoconnect", self.signal.name];
}

@end
