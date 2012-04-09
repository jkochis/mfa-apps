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

#define RETRY_COUNT 1

@protocol HTTPBundleManagerDelegate;

@interface HTTPBundleManager : NSObject <UpdaterDataProviderDelegate, HTTPRequestDelegate> {

	id<HTTPBundleManagerDelegate> delegate;
	
	UpdaterDataProvider *dataProvider;
	
	HTTPRequest *httpRequest;
	NSInteger retries;
	
	NSFileManager *fileManager;
	NSString *documentsDirectory;
	NSString *bundleName;
	NSURL *bundleUrl;
	NSMutableArray *bundleFiles;
	NSMutableArray *updatableFiles;
	NSUInteger skipToFile;
	BOOL quickUpdate;
	
	NSDate *currentModificationDate;
	NSUInteger currentFile;
	
	NSUInteger totalFiles;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) HTTPRequest *httpRequest;
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, readonly) NSString *documentsDirectory;
@property (nonatomic, retain) NSString *bundleName;
@property (nonatomic, retain) NSURL *bundleUrl;
@property (nonatomic, retain) NSMutableArray *bundleFiles;
@property (nonatomic, retain) NSMutableArray *updatableFiles;
@property (nonatomic, retain) NSDate *currentModificationDate;

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withTourML:(NSURL *)tourMLUrl;
- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withTourML:(NSURL *)tourMLUrl startingWithFile:(NSUInteger)file;
- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withFiles:(NSArray *)files;
- (BOOL)removeBundle:(NSString *)theBundleName error:(NSError **)error;
- (void)cancel;

@end

@protocol HTTPBundleManagerDelegate <NSObject>

- (void)bundleManager:(HTTPBundleManager *)bundleManager didFailToRetrieveTourML:(NSURL *)tourMLUrl;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didFailWithError:(NSError *)error;

@optional

- (void)bundleManager:(HTTPBundleManager *)bundleManager didRetryFile:(NSString *)filePath retryCount:(NSInteger)retries;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didStartUpdatingFile:(NSString *)filePath fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didRecieveBytes:(NSInteger)bytes outOfTotalBytes:(NSInteger)totalBytes forFile:(NSString *)filePath;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didFinishUpdatingFile:(NSString *)filePath fileNumber:(NSUInteger)fileNumber outOf:(NSUInteger)totalFiles;
- (void)bundleManager:(HTTPBundleManager *)bundleManager didRemoveFile:(NSString *)filePath;
- (void)bundleManagerCompletedUpdate:(HTTPBundleManager *)bundleManager;
- (void)bundleManagerCompletedQuickUpdate:(HTTPBundleManager *)bundleManager;

@end

