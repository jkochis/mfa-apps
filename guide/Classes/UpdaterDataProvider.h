//
//  UpdaterDataProvider.h
//  Test
//
//  Created by Robert Brecher on 9/16/10.
//  Copyright 2010 Genuine Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libxml/tree.h>
#import <libxml/parser.h>
#import <libxml/xpath.h>
#import <libxml/xpathInternals.h>

#define UPDATER_URL @"http://mfa-newmedia/drupal-6.17/all-tours"
//#define UPDATER_URL @"http://10.10.12.73/tours.xml"
//#define UPDATER_URL @"http://192.168.1.2/tours.xml"

@protocol UpdaterDataProviderDelegate;

@interface UpdaterDataProvider : NSObject {
	id<UpdaterDataProviderDelegate> delegate;
	NSURLConnection *urlConnection;
	NSMutableData *webData;
	NSUInteger currentRequest;
}

@property (nonatomic, retain) id delegate;

- (id)initWithDelegate:(id<UpdaterDataProviderDelegate>)theDelegate;

- (void)getLatest;
- (void)getTourML:(NSURL *)tourMLUrl;
- (void)cancel;

@end

@protocol UpdaterDataProviderDelegate <NSObject>

- (void)dataProvider:(UpdaterDataProvider *)dataProvider didFailWithError:(NSError *)error;

@optional

- (void)dataProvider:(UpdaterDataProvider *)dataProvider didRetrieveTours:(NSArray *)tours;
- (void)dataProvider:(UpdaterDataProvider *)dataProvider didRetrieveTourML:(xmlDocPtr)tourDoc;

@end