//
//  BackgroundUpdater.h
//  MFA Guide
//
//  Created by Robert Brecher on 9/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Updater.h"

@protocol BackgroundUpdaterDelegate;

@interface BackgroundUpdater : NSObject <UpdaterDelegate> {
	id<BackgroundUpdaterDelegate> delegate;
	Updater *updater;
	BOOL isUpdating;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) Updater *updater;
@property (nonatomic, assign) BOOL isUpdating;

- (id)initWithDelegate:(id<BackgroundUpdaterDelegate>)theDelegate;
- (void)update;

@end

@protocol BackgroundUpdaterDelegate <NSObject>

- (void)backgroundUpdaterDidFinishUpdating:(BackgroundUpdater *)backgroundUpdater;
- (void)backgroundUpdater:(BackgroundUpdater *)backgroundUpdater didFailWithError:(NSError *)error;

@end