#import "ImageStop.h"

#import "ImageStopController.h"


@implementation ImageStop

- (NSString *)getSourcePath
{
	for (xmlNodePtr child = stopNode->children; child != NULL; child = child->next) {
		if (xmlStrEqual(child->name, (xmlChar*)"Source")) {
			char *source = (char*)xmlNodeGetContent(child);
			NSString *result = [[NSString stringWithUTF8String:source] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			free(source);
			return result;
		}
	}
	
	return nil;
}

#pragma mark BaseStop

- (NSString *)getIconPath
{
	return [[NSBundle mainBundle] pathForResource:@"icon-image" ofType:@"png"];
}

- (NSArray *)getAllFiles
{
	return [NSArray arrayWithObject:[self getSourcePath]];
}

- (BOOL)providesViewController
{
	return YES;
}

- (UIViewController *)newViewController
{
	return [[ImageStopController alloc] initWithImageStop:self];
}

@end
