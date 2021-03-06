#import "BaseStop.h"


@implementation BaseStop

@synthesize stopNode;

- (id)initWithStopNode:(xmlNodePtr)stop
{
	if ((self = [super init])) {
		[self setStopNode:stop];
	}
	
	return self;
}

- (NSString *)getStopId
{
	char *propId = (char*)xmlGetProp(stopNode, (xmlChar*)"id");
    NSString *result = [NSString stringWithUTF8String:propId];
	xmlFree(propId);
	return result;
}

- (NSString *)getStopCode
{
	char *propCode = (char*)xmlGetProp(stopNode, (xmlChar*)"code");
    NSString *result = [NSString stringWithUTF8String:propCode];
	xmlFree(propCode);
	return result;
}

- (NSString *)getTitle
{
	for (xmlNodePtr child = stopNode->children; child != NULL; child = child->next) {
		if (xmlStrEqual(child->name, (xmlChar*)"Title")) {
			char *title = (char*)xmlNodeGetContent(child);
			NSString *result = [NSString stringWithUTF8String:title];
			free(title);
			return result;
		}
	}
	
	return nil;
}

- (NSString *)getDescription
{
	for (xmlNodePtr child = stopNode->children; child != NULL; child = child->next) {
		if (xmlStrEqual(child->name, (xmlChar*)"Description")) {
			char *desc = (char*)xmlNodeGetContent(child);
			NSString *result = [NSString stringWithUTF8String:desc];
			free(desc);
			return result;
		}
	}
	
	return nil;
}

- (NSString *)getIconPath
{
	// Default case if we get here
	return [[NSBundle mainBundle] pathForResource:@"icon-webpage" ofType:@"png"];
}

- (NSDate *)getUpdateDate
{
	NSDate *updateDate = nil;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	for (xmlNodePtr child = stopNode->children; child != NULL; child = child->next) {
		if (xmlStrEqual(child->name, (xmlChar*)"UpdateDate")) {
			char *desc = (char*)xmlNodeGetContent(child);
			NSString *result = [NSString stringWithUTF8String:desc];
			updateDate = [dateFormatter dateFromString:result];
			free(desc);
			break;
		}
	}
	[dateFormatter release];
	
	return updateDate;
}

- (NSArray *)getAllFiles
{
	// Override this in subclasses to provide an accurate list
	return nil;
}

- (BOOL)providesViewController
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

- (UIViewController *)newViewController
{
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

- (BOOL)loadStopView
{
	[self doesNotRecognizeSelector:_cmd];
	return NO;
}

@end
