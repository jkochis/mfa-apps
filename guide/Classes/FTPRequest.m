//
//  FTPRequest.m
//  Test
//
//  Created by Robert Brecher on 9/17/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "FTPRequest.h"

enum {
	kDirectoryRequest = 0,
	kFileRequest = 1
};

@interface FTPRequest (PrivateMethods)

- (void)parseDirectoryData;
- (void)dispatchAndCleanUpDirectories;
- (void)dispatchError:(NSError *)error;

@end


@implementation FTPRequest

@synthesize delegate, userName, password, inputStream, directoryData, directoryEntries, filePath, outputStream;

- (id)initWithUserName:(NSString *)theUserName andPassword:(NSString *)thePassword
{
	if ((self = [super init])) {
		[self setUserName:theUserName];
		[self setPassword:thePassword];
	}
	return self;
}

- (void)dealloc
{
	[delegate release];
	[userName release];
	[password release];
	[inputStream release];
	[directoryData release];
	[directoryEntries release];
	[filePath release];
	[outputStream release];
	[super dealloc];
}

#pragma mark -
#pragma mark Directory Methods

- (void)retrieveDirectory:(NSURL *)directory
{	
	requestType = kDirectoryRequest;
	
	[self setDirectoryData:[NSMutableData data]];
	[self setDirectoryEntries:[NSMutableArray array]];
	
	CFReadStreamRef ftpStream = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)directory);
	if (ftpStream) {
		if (userName && password) {
			CFReadStreamSetProperty(ftpStream, kCFStreamPropertyFTPUserName, userName);
			CFReadStreamSetProperty(ftpStream, kCFStreamPropertyFTPPassword, password);
		}
		[self setInputStream:(NSInputStream *)ftpStream];
		[inputStream setDelegate:self];
		[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[inputStream open];
		CFRelease(ftpStream);
	}
	else {
		[self dispatchError:nil];
	}
}

- (void)parseDirectoryData
{
	NSMutableArray *newEntries = [NSMutableArray array];
	NSUInteger offset = 0;
	do {
		CFDictionaryRef thisEntry;
		CFIndex bytesConsumed = CFFTPCreateParsedResourceListing(NULL, &((const uint8_t *)[directoryData bytes])[offset], [directoryData length] - offset, &thisEntry);
		if (bytesConsumed > 0) {
			if (thisEntry != NULL) {
				[newEntries addObject:(NSDictionary *)thisEntry];
			}
			offset += bytesConsumed;
		}
		if (thisEntry != NULL) {
			CFRelease(thisEntry);
		}
		if (bytesConsumed == 0) {
			break;
		}
		else if (bytesConsumed < 0) {
			[self dispatchError:nil];
			break;
		}
	} while(YES);
	if ([newEntries count] != 0) {
		[directoryEntries addObjectsFromArray:newEntries];
	}
	if (offset != 0) {
		[directoryData replaceBytesInRange:NSMakeRange(0, offset) withBytes:NULL length:0];
	}
}

- (void)dispatchAndCleanUpDirectories
{
	if ([delegate respondsToSelector:@selector(ftpRequest:didRetrieveDirectory:)]) {
		[delegate ftpRequest:self didRetrieveDirectory:directoryEntries];
	}
//	directoryData = nil;
//	directoryEntries = nil;
}

#pragma mark -
#pragma mark File Methods

- (void)retrieveFile:(NSURL *)pathToFile
{	
	requestType = kFileRequest;
	
	[self setFilePath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temporary-file"]];
	[self setOutputStream:[NSOutputStream outputStreamToFileAtPath:filePath append:NO]];
	[outputStream open];
	
	currentBytes = 0;
	NSURL *readUrl = pathToFile;
	CFReadStreamRef ftpStream = CFReadStreamCreateWithFTPURL(NULL, (CFURLRef)readUrl);
	if (userName && password) {
		CFReadStreamSetProperty(ftpStream, kCFStreamPropertyFTPUserName, userName);
		CFReadStreamSetProperty(ftpStream, kCFStreamPropertyFTPPassword, password);
	}
	[self setInputStream:(NSInputStream *)ftpStream];
	[inputStream setDelegate:self];
	[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[inputStream open];
	CFRelease(ftpStream);
}

- (void)writeFile
{	
	if ([delegate respondsToSelector:@selector(ftpRequest:didRetrieveFile:)]) {
		[delegate ftpRequest:self didRetrieveFile:filePath];
	}
//	filePath = nil;
}

#pragma mark -
#pragma mark Generic Methods

- (void)dispatchError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(ftpRequest:didFailWithError:)]) {
		[delegate ftpRequest:self didFailWithError:error];
	}
}

- (void)cleanupStreams
{
	if (inputStream) {
		[inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[inputStream setDelegate:nil];
		[inputStream close];
		[inputStream release];
		inputStream = nil;
	}
	if (outputStream) {
		[outputStream close];
		[outputStream release];
		outputStream = nil;
	}
}

#pragma mark -
#pragma mark NSStreamDelegate Methods

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent
{
	switch (streamEvent) {
		case NSStreamEventHasBytesAvailable: {
			NSInteger bytesRead;
			uint8_t buffer[32768];
			bytesRead = [inputStream read:buffer maxLength:sizeof(buffer)];
			if (bytesRead == -1) {
				[self dispatchError:nil];
			}
			else if (bytesRead == 0) {
				[self cleanupStreams];
				if (requestType == kDirectoryRequest) {
					[self dispatchAndCleanUpDirectories];
				}
				else if (requestType == kFileRequest) {
					[self writeFile];
				}
			}
			else {
				if (requestType == kDirectoryRequest) {
					[directoryData appendBytes:buffer length:bytesRead];
					[self parseDirectoryData];
				}
				else if (requestType == kFileRequest) {
					NSInteger bytesWritten;
					NSInteger totalBytesWritten;
					totalBytesWritten = 0;
					do {
						bytesWritten = [outputStream write:&buffer[totalBytesWritten] maxLength:bytesRead - totalBytesWritten];
						if (bytesWritten == -1) {
							[self dispatchError:nil];
							break;
						}
						else {
							totalBytesWritten += bytesWritten;
						}
						
					} while (totalBytesWritten != bytesRead);
					currentBytes += totalBytesWritten;
					if ([delegate respondsToSelector:@selector(ftpRequest:didRetrieveBytes:)]) {
						[delegate ftpRequest:self didRetrieveBytes:currentBytes];
					}
				}
			}
			break;
		}
		case NSStreamEventErrorOccurred: {
			[self dispatchError:[inputStream streamError]];
			break;
		}
		default: {
			break;
		}
	}
}

@end
