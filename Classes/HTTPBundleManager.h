//
//  HTTPBundleManager.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/11/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HTTPRequest.h"
#import "UpdaterDataProvider.h"

#define RETRY_COUNT 3

@protocol HTTPBundleManagerDelegate;

@interface HTTPBundleManager : NSObject <UpdaterDataProviderDelegate, HTTPRequestDelegate> {

	id<HTTPBundleManagerDelegate> delegate;
	
	UpdaterDataProvider *dataProvider;
	
	HTTPRequest *httpRequest;
	NSInteger retries;
	
	NSFileManager *fileManager;
	NSString *bundleName;
	NSURL *bundleUrl;
	NSMutableArray *bundleFiles;
	
	NSUInteger currentFile;
	NSUInteger totalFiles;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) HTTPRequest *httpRequest;
@property (nonatomic, retain) NSFileManager *fileManager;

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withTourML:(NSURL *)tourMLUrl;

@end

@protocol HTTPBundleManagerDelegate <NSObject>

- (void)bundleManager:(HTTPBundleManager *)bundleManager didFailToRetrieveTourML:(NSURL *)tourMLUrl;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didFailWithError:(NSError *)error;

@optional

- (void)bundleManager:(HTTPBundleManager *)bundleManager didRetryFile:(NSString *)pathToFile retryCount:(NSInteger)retries;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didStartUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)pathToFile;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didFinishUpdatingFile:(NSString *)pathToFile fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)bundleManagerCompletedUpdate:(HTTPBundleManager *)bundleManager;

@end

