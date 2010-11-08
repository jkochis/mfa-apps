//
//  MFAUpdaterViewController.m
//  MFAUpdater
//
//  Created by Robert Brecher on 10/21/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import "MFAUpdaterViewController.h"

@implementation MFAUpdaterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:UPDATER_URL]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	
}

- (void)dealloc
{
    [super dealloc];
}

@end
