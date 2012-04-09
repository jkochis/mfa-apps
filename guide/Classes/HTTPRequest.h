//
//  HTTPRequest.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/11/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
	HTTPRequestFileIsDirectoryError = 1002
};

@protocol HTTPRequestDelegate;

@interface HTTPRequest : NSObject {
	
	id<HTTPRequestDelegate> delegate;
	NSURLConnection *urlConnection;
	NSURL *remoteUrl;
	NSString *filePath;
	NSFileHandle *fileHandle;
	NSUInteger totalBytes;
	NSUInteger currentBytes;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NSURLConnection *urlConnection;
@property (nonatomic, retain) NSURL *remoteUrl;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSFileHandle *fileHandle;

- (void)retrieveFile:(NSURL *)fileUrl;
- (void)cancel;

@end

@protocol HTTPRequestDelegate <NSObject>

- (void)httpRequest:(HTTPRequest *)httpRequest didFailWithError:(NSError *)error;

@optional

- (BOOL)httpRequest:(HTTPRequest *)httpRequest shouldRetrieveFile:(NSURL *)remoteUrl withModificationDate:(NSDate *)modificationDate;
- (void)httpRequest:(HTTPRequest *)httpRequest didCancelFile:(NSURL	*)remoteUrl;
- (void)httpRequest:(HTTPRequest *)httpRequest didReceiveBytes:(NSUInteger)bytes outOf:(NSUInteger)totalBytes;
- (void)httpRequest:(HTTPRequest *)httpRequest didRetrieveFile:(NSString *)filePath;

@end