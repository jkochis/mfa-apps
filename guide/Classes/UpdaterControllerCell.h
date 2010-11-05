//
//  UpdaterControllerCell.h
//  MFA Guide
//
//  Created by Robert Brecher on 10/7/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UpdaterControllerCell : UITableViewCell {

	IBOutlet UILabel *textLabel;
	IBOutlet UILabel *detailTextLabel;
	IBOutlet UIProgressView *progressView;
	IBOutlet UILabel *fileCount;
}

@property (nonatomic, retain) IBOutlet UILabel *textLabel;
@property (nonatomic, retain) IBOutlet UILabel *detailTextLabel;
@property (nonatomic, retain) IBOutlet UIProgressView *progressView;
@property (nonatomic, retain) IBOutlet UILabel *fileCount;

@end
