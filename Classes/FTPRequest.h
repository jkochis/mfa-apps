//
//  FTPRequest.h
//  Test
//
//  Created by Robert Brecher on 9/17/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol FTPRequestDelegate;

@interface FTPRequest : NSObject <NSStreamDelegate> {
	id<FTPRequestDelegate> delegate;
	NSString *userName;
	NSString *password;
	NSInputStream *inputStream;
    NSMutableData *directoryData;
	NSMutableArray *directoryEntries;
	NSString *filePath;
    NSOutputStream *fileStream;
	NSInteger currentBytes;
	int requestType;
}

@property (nonatomic, retain) id delegate;
@property (nonatomic, retain) NSString *userName;
@property (nonatomic, retain) NSString *password;
@property (nonatomic, retain) NSInputStream *inputStream;
@property (nonatomic, retain) NSMutableData *directoryData;
@property (nonatomic, retain) NSMutableArray *directoryEntries;
@property (nonatomic, retain) NSString *filePath;
@property (nonatomic, retain) NSOutputStream *outputStream;

- (id)initWithUserName:(NSString *)theUserName andPassword:(NSString *)thePassword;

- (void)retrieveDirectory:(NSURL *)directory;
- (void)retrieveFile:(NSURL *)pathToFile;

@end

@protocol FTPRequestDelegate <NSObject>

- (void)ftpRequest:(FTPRequest *)ftpRequest didFailWithError:(NSError *)error;

@optional

- (void)ftpRequest:(FTPRequest *)ftpRequest didRetrieveDirectory:(NSArray *)directory;
- (void)ftpRequest:(FTPRequest *)ftpRequest didRetrieveBytes:(NSInteger)bytes;
- (void)ftpRequest:(FTPRequest *)ftpRequest didRetrieveFile:(NSString *)pathToFile;

@end

