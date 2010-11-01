//
//  HTTPBundleManager.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/11/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "HTTPBundleManager.h"

#import "BaseStop.h"
#import "StopFactory.h"
#import "TourController.h"

@interface HTTPBundleManager (PrivateMethods)

- (void)buildFileList:(xmlDocPtr)tourDoc;
- (BOOL)writeTourML:(xmlDocPtr)tourDoc error:(NSError **)error;
- (BOOL)checkOrCreateDirectory:(NSString *)directory error:(NSError **)error;
- (void)retrieveNextFile;

@end


@implementation HTTPBundleManager

@synthesize delegate, httpRequest, fileManager;

- (HTTPRequest *)httpRequest
{
	if (!httpRequest) {
		httpRequest = [[HTTPRequest alloc] init];
		[httpRequest setDelegate:self];
	}
	return httpRequest;
}

- (NSFileManager *)fileManager
{
	// Lazy initializer
	if (!fileManager) {
		fileManager = [[NSFileManager alloc] init];
	}
	return fileManager;
}

- (void)dealloc
{
	[delegate release];
	[dataProvider release];
	[httpRequest release];
	[fileManager release];
	[bundleName release];
	[bundleUrl release];
	[bundleFiles release];
	[super dealloc];
}

#pragma mark -
#pragma mark Bundles

- (void)retrieveOrUpdateBundle:(NSString *)theBundleName withTourML:(NSURL *)tourMLUrl
{
	bundleName = [theBundleName retain];
	bundleUrl = [tourMLUrl retain];
	dataProvider = [[UpdaterDataProvider alloc] initWithDelegate:self];
	[dataProvider getTourML:tourMLUrl];
}

- (void)cancel
{
	if (dataProvider) {
		[dataProvider cancel];
	}
	if (httpRequest) {
		[httpRequest cancel];
	}
}

- (void)buildFileList:(xmlDocPtr)tourDoc
{
	// Generate a list of bundle files
	bundleFiles = [[NSMutableArray alloc] init];
		
	// Get splash image
	xmlNodePtr imageNode = [TourMLUtils getImageInDocument:tourDoc];
	if (imageNode) {
		char *imageChars = (char*)xmlNodeGetContent(imageNode);
		NSString *imageSrc = [NSString stringWithUTF8String:imageChars];
		[bundleFiles addObject:imageSrc];
		free(imageChars);
	}
	
	// Get sponsor image
	xmlNodePtr sponsorImageNode = [TourMLUtils getImageInDocument:tourDoc];
	if (sponsorImageNode) {
		char *sponsorImageChars = (char*)xmlNodeGetContent(sponsorImageNode);
		NSString *sponsorImageSrc = [NSString stringWithUTF8String:sponsorImageChars];
		[bundleFiles addObject:sponsorImageSrc];
		free(sponsorImageChars);
	}
	
	// Add remaining files from tour
	xmlNodeSetPtr stopNodes = [TourMLUtils getAllStopsInDocument:tourDoc];
	for (NSInteger i = 0; i < stopNodes->nodeNr; i++)
	{
		xmlNodePtr stopNode = stopNodes->nodeTab[i];
		BaseStop *stop = [StopFactory stopForStopNode:stopNode];
		if (stop) {
			[bundleFiles addObjectsFromArray:[stop getAllFiles]];
		}
	}
	xmlXPathFreeNodeSet(stopNodes);
	[bundleFiles sortUsingComparator:^(id obj1, id obj2) {
		return [(NSString *)obj1 compare:(NSString *)obj2];
	}];
	
	// Write TourML file, bail if there's an error
	NSError *error = nil;
	if (![self writeTourML:tourDoc error:&error]) {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		return;
	}
	
	// Prep for download
	currentFile = 0;
	totalFiles = [bundleFiles count];
	[self retrieveNextFile];
}

- (BOOL)writeTourML:(xmlDocPtr)tourDoc error:(NSError **)error
{
	// Shorten path for <Image>
	xmlNodePtr imageNode = [TourMLUtils getImageInDocument:tourDoc];
	if (imageNode) {
		char *imageChars = (char*)xmlNodeGetContent(imageNode);
		NSString *imageSrc = [NSString stringWithUTF8String:imageChars];
		xmlNodeSetContent(imageNode, (xmlChar*)[[NSString stringWithFormat:@"files/%@", [imageSrc lastPathComponent]] UTF8String]);
		free(imageChars);
	}
	
	// Shorten path for <SponsorImage>
	xmlNodePtr sponsorImageNode = [TourMLUtils getImageInDocument:tourDoc];
	if (sponsorImageNode) {
		char *sponsorImageChars = (char*)xmlNodeGetContent(sponsorImageNode);
		NSString *sponsorImageSrc = [NSString stringWithUTF8String:sponsorImageChars];
		xmlNodeSetContent(sponsorImageNode, (xmlChar*)[[NSString stringWithFormat:@"files/%@", [sponsorImageSrc lastPathComponent]] UTF8String]);
		free(sponsorImageChars);
	}
	
	// Shorten path for <Source> nodes 
	xmlNodeSetPtr sourceNodes = [TourMLUtils getAllSourceNodesInDocument:tourDoc];
	if (sourceNodes) {
		for (NSInteger i = 0; i < sourceNodes->nodeNr; i++)
		{
			xmlNodePtr sourceNode = sourceNodes->nodeTab[i];
			char *sourceChars = (char*)xmlNodeGetContent(sourceNode);
			NSString *sourceString = [NSString stringWithUTF8String:sourceChars];
			xmlNodeSetContent(sourceNode, (xmlChar*)[[NSString stringWithFormat:@"files/%@", [sourceString lastPathComponent]] UTF8String]);
			free(sourceChars);
		}
	}
	xmlXPathFreeNodeSet(sourceNodes);
	
	// Shorten path for <Param> nodes being used for image headers 
	xmlNodeSetPtr headerNodes = [TourMLUtils getAllHeaderNodesInDocument:tourDoc];
	if (headerNodes) {
		for (NSInteger i = 0; i < headerNodes->nodeNr; i++)
		{
			xmlNodePtr headerNode = headerNodes->nodeTab[i];
			char *valueChars = (char*)xmlGetProp(headerNode, (xmlChar*)"value");
			NSString *valueString = [NSString stringWithUTF8String:valueChars];
			xmlSetProp(headerNode, (xmlChar*)"value", (xmlChar*)[[NSString stringWithFormat:@"files/%@", [valueString lastPathComponent]] UTF8String]);
			free(valueChars);
		}
	}
	xmlXPathFreeNodeSet(headerNodes);
	
	// Prepare to write file
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
	NSString *localPath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.bundle/tour.xml", bundleName]];
	NSString *localDirectory = [localPath stringByDeletingLastPathComponent];
	
	// Bail if directory can't be created
	if (![self checkOrCreateDirectory:localDirectory error:error]) {
		return NO;
	}
	
	// Build string and write
	xmlChar *xmlBuff;
	int buffSize;
	xmlDocDumpFormatMemory(tourDoc, &xmlBuff, &buffSize, 1);
	[[NSString stringWithUTF8String:(char*)xmlBuff] writeToFile:localPath atomically:NO encoding:NSUTF8StringEncoding error:error];
	if (*error) {
		NSLog(@"Error writing XML: %@", [*error localizedDescription]);
	}
	return YES;
}

- (BOOL)checkOrCreateDirectory:(NSString *)directory error:(NSError **)error
{
	BOOL isDir;
	if (!([[self fileManager] fileExistsAtPath:directory isDirectory:&isDir] && isDir)) {
		[fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:error];
		if (*error) {
			return NO;
		}
	}
	return YES;
}

- (void)retrieveNextFile
{
	// If no files remain, notify delegate and quit
	if ([bundleFiles count] == 0) {
		if ([delegate respondsToSelector:@selector(bundleManagerCompletedUpdate:)]) {
			[delegate bundleManagerCompletedUpdate:self];
		}
		[httpRequest release];
		httpRequest = nil;
		return;
	}
	
	// Otherwise, retrieve the next file
	currentFile++;
	retries = 0;
	NSString *fullPath = [[bundleFiles objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	[[self httpRequest] retrieveFile:[NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	if ([delegate respondsToSelector:@selector(bundleManager:didStartUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		   didStartUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/files/%@", bundleName, [fullPath lastPathComponent]] 
					 fileNumber:currentFile 
						  outOf:totalFiles];
	}
}

- (void)retryFile
{
	NSString *fullPath = [[bundleFiles objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	[[self httpRequest] retrieveFile:[NSURL URLWithString:[fullPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	if ([delegate respondsToSelector:@selector(bundleManager:didRetryFile:retryCount:)]) {
		[delegate bundleManager:self didRetryFile:[NSString stringWithFormat:@"/%@.bundle/files/%@", bundleName, [fullPath lastPathComponent]] retryCount:retries];
	}
}

#pragma mark -
#pragma mark UpdaterDataProviderDelegate Methods

- (void)dataProvider:(UpdaterDataProvider *)theDataProvider didFailWithError:(NSError *)error
{
	if ([delegate respondsToSelector:@selector(bundleManager:didFailToRetrieveTourML:)]) {
		[delegate bundleManager:self didFailToRetrieveTourML:bundleUrl];
	}
}

- (void)dataProvider:(UpdaterDataProvider *)theDataProvider didRetrieveTourML:(xmlDocPtr)tourDoc
{
	[self buildFileList:tourDoc];
	[dataProvider release];
	dataProvider = nil;
}

#pragma mark -
#pragma mark HTTPRequestDelegate Methods

- (void)httpRequest:(HTTPRequest *)httpRequest didFailWithError:(NSError *)error
{
	if (++retries < RETRY_COUNT) {
		[self retryFile];
	}
	else {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		[bundleFiles removeObjectAtIndex:0];
		[self retrieveNextFile];
	}
}

- (BOOL)httpRequest:(HTTPRequest *)httpRequest shouldRetrieveFile:(NSURL *)pathToFile withModificationDate:(NSDate *)modificationDate
{
	// Get local path using relative path
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[pathToFile path] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
	NSString *localPath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]];

	// Check to see if the file already exists
	if ([[self fileManager] fileExistsAtPath:localPath]) {
		
		// If so, compare updated date to file on server and skip if newer
		NSError *error = nil;
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:localPath error:&error];
		if (error) {
			NSLog(@"File attribute error: %@", [error localizedDescription]);
			return YES;
		}
		if ([[fileAttributes fileModificationDate] timeIntervalSinceDate:modificationDate] >= 0) {
			return NO;
		}
	}
	return YES;
}

- (void)httpRequest:(HTTPRequest *)httpRequest didCancelFile:(NSURL	*)remotePath
{
	// Send notification to delegate
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[bundleFiles objectAtIndex:0] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([delegate respondsToSelector:@selector(bundleManager:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		  didFinishUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]
					 fileNumber:currentFile
						  outOf:totalFiles];
	}
	[bundleFiles removeObjectAtIndex:0];
	[self retrieveNextFile];
}

- (void)httpRequest:(HTTPRequest *)httpRequest didReceiveBytes:(NSUInteger)bytes outOf:(NSUInteger)totalBytes
{	
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[bundleFiles objectAtIndex:0] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	if ([delegate respondsToSelector:@selector(bundleManager:didRecieveBytes:outOfTotalBytes:forFile:)]) {
		[delegate bundleManager:self didRecieveBytes:bytes outOfTotalBytes:totalBytes forFile:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]];
	}
}

- (void)httpRequest:(HTTPRequest *)httpRequest didRetrieveFile:(NSString *)pathToFile
{	
	// Gather information
	NSString *relativePath = [NSString stringWithFormat:@"files/%@", [[[bundleFiles objectAtIndex:0] lastPathComponent] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
	NSArray *documentsPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [documentsPaths objectAtIndex:0];
	NSString *localPath = [documentsDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]];
	NSString *localDirectory = [localPath stringByDeletingLastPathComponent];
	 
	// Check to see if directory exists, and if not create it
	NSError *error = nil;
	if (![self checkOrCreateDirectory:localDirectory error:&error]) {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		return;
	}
	
	// Check to see if file exists, and if so remove it
	if ([fileManager fileExistsAtPath:localPath]) {
		[fileManager removeItemAtPath:localPath error:&error];
		if (error) {
			if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
				[delegate bundleManager:self didFailWithError:error];
			}
			return;
		}
	}
	
	// Move temporary file into bundle
	[fileManager moveItemAtPath:pathToFile toPath:localPath error:&error];
	if (error) {
		if ([delegate respondsToSelector:@selector(bundleManager:didFailWithError:)]) {
			[delegate bundleManager:self didFailWithError:error];
		}
		return;
	}
	
	// Send notification to delegate
	if ([delegate respondsToSelector:@selector(bundleManager:didFinishUpdatingFile:fileNumber:outOf:)]) {
		[delegate bundleManager:self 
		  didFinishUpdatingFile:[NSString stringWithFormat:@"/%@.bundle/%@", bundleName, relativePath]
					 fileNumber:currentFile
						  outOf:totalFiles];
	}
	
	// Start on next file
	[bundleFiles removeObjectAtIndex:0];
	[self retrieveNextFile];
}

@end
