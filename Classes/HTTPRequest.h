//
//  HTTPRequest.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/11/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTTPRequestDelegate;

@interface HTTPRequest : NSObject {
	
	id<HTTPRequestDelegate> delegate;
	NSURLConnection *urlConnection;
	NSURL *remotePath;
	NSString *filePath;
	NSFileHandle *fileHandle;
	NSUInteger totalBytes;
	NSUInteger currentBytes;
}

@property (nonatomic, retain) id delegate;

- (void)retrieveFile:(NSURL *)pathToFile;
- (void)cancel;

@end

@protocol HTTPRequestDelegate <NSObject>

- (void)httpRequest:(HTTPRequest *)httpRequest didFailWithError:(NSError *)error;

@optional

- (BOOL)httpRequest:(HTTPRequest *)httpRequest shouldRetrieveFile:(NSURL *)remotePath withModificationDate:(NSDate *)modificationDate;
- (void)httpRequest:(HTTPRequest *)httpRequest didCancelFile:(NSURL	*)remotePath;
- (void)httpRequest:(HTTPRequest *)httpRequest didReceiveBytes:(NSUInteger)bytes outOf:(NSUInteger)totalBytes;
- (void)httpRequest:(HTTPRequest *)httpRequest didRetrieveFile:(NSString *)pathToFile;

@end