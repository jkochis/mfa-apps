//
//  UpdaterControllerCell.m
//  MFA Guide
//
//  Created by Robert Brecher on 10/7/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "UpdaterControllerCell.h"


@implementation UpdaterControllerCell

@synthesize textLabel, detailTextLabel, progressView, fileCount;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
        
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void)dealloc
{
	[textLabel release];
	[detailTextLabel release];
	[progressView release];
	[fileCount release];
    [super dealloc];
}


@end
