//
//  HTTPRequest.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/11/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "HTTPRequest.h"

@interface HTTPRequest (PrivateMethods)

- (void)cleanup;

@end


@implementation HTTPRequest

@synthesize delegate;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
	[delegate release];
	[urlConnection release];
	[remotePath release];
	[filePath release];
	[fileHandle release];
	[super dealloc];
}

#pragma mark -
#pragma mark Retrieving Files

- (void)retrieveFile:(NSURL *)pathToFile
{	
	[self cleanup];
	remotePath = [pathToFile retain];
	NSURLRequest *urlRequest = [[NSURLRequest alloc] initWithURL:pathToFile];
	urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	if (urlConnection) {
		NSString *tempPath = NSTemporaryDirectory();
		filePath = [[tempPath stringByAppendingPathComponent:[NSString stringWithFormat:@"org.mfa.tap.updater_temp_%f", [NSDate timeIntervalSinceReferenceDate]]] retain];
		[[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
		fileHandle = [[NSFileHandle fileHandleForWritingAtPath:filePath] retain];
	}
	[urlRequest release];
}

- (void)cancel
{
	if (urlConnection) {
		[urlConnection cancel];
		[urlConnection release];
		urlConnection = nil;
	}
}

- (void)cleanup
{
	[remotePath release];
	remotePath = nil;
	[filePath release];
	filePath = nil;
	[fileHandle release];
	fileHandle = nil;
	[urlConnection release];
	urlConnection = nil;
}

#pragma mark -
#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	// Check status code
	if ([response isMemberOfClass:[NSHTTPURLResponse class]] && [(NSHTTPURLResponse *)response statusCode] != 200) {
		[connection cancel];
		if ([delegate respondsToSelector:@selector(httpRequest:didFailWithError:)]) {
			NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@: HTTP Status Code: %ld", remotePath, [(NSHTTPURLResponse *)response statusCode]], NSLocalizedDescriptionKey, remotePath, NSURLErrorFailingURLErrorKey, nil];
			NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:dict];
			[delegate httpRequest:self didFailWithError:error];
		}
	}
	
	// Set current bytes and total bytes
	currentBytes = 0;
	totalBytes = (NSUInteger)[response expectedContentLength];
	
	// Seek to the beginning of the file handle, just in case
	[fileHandle seekToFileOffset:0];
	
	// If response is an NSHTTPURLResponse, use the Last-Modified header to check against local file
	if ([response isMemberOfClass:[NSHTTPURLResponse class]] &&
		[delegate respondsToSelector:@selector(httpRequest:shouldRetrieveFile:withModificationDate:)]) {
		
		// Get date from header and use delegate to compare
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
		NSString *dateString = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Last-Modified"];
		NSDate *date = [dateFormatter dateFromString:dateString];
		[dateFormatter release];
		
		// Check date against delegate
		if (![delegate httpRequest:self shouldRetrieveFile:remotePath withModificationDate:date]) {
			[connection cancel];
			if ([delegate respondsToSelector:@selector(httpRequest:didCancelFile:)]) {
				[delegate httpRequest:self didCancelFile:remotePath];
			}
		}
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[fileHandle writeData:data];
	currentBytes += [data length];
	if ([delegate respondsToSelector:@selector(httpRequest:didReceiveBytes:outOf:)]) {
		[delegate httpRequest:self didReceiveBytes:currentBytes outOf:totalBytes];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{	
	if ([delegate respondsToSelector:@selector(httpRequest:didFailWithError:)]) {
		[delegate httpRequest:self didFailWithError:error];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{	
	if ([delegate respondsToSelector:@selector(httpRequest:didRetrieveFile:)]) {
		[delegate httpRequest:self didRetrieveFile:filePath];
	}
}

@end
