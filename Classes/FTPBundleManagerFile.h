//
//  FTPBundleManagerFile.h
//  MFA Guide
//
//  Created by Robert Brecher on 9/22/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FTPBundleManagerFile : NSObject {
	NSString *filename;
	NSString *path;
	NSNumber *size;
	NSDate *modificationDate;
	
}

@property (nonatomic, retain) NSString *filename;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSNumber *size;
@property (nonatomic, retain) NSDate *modificationDate;

- (id)initWithFilename:(NSString *)theFilename path:(NSString *)thePath size:(NSNumber *)theSize modificationDate:(NSDate *)theModificationDate;

@end
