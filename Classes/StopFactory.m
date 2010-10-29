#import "StopFactory.h"


@implementation StopFactory

+ (id)stopForStopNode:(xmlNodePtr)stop
{
	if (!stop) {
		// Produce error?
		return nil;
	}
	if (xmlStrEqual(stop->name, (xmlChar*)"ImageStop"))
	{
		return [[[ImageStop alloc] initWithStopNode:stop] autorelease];
	}
	if (xmlStrEqual(stop->name, (xmlChar*)"PollStop"))
	{
		return [[[PollStop alloc] initWithStopNode:stop] autorelease];
	}
	if (xmlStrEqual(stop->name, (xmlChar*)"StopGroup"))
	{
		return [[[StopGroup alloc] initWithStopNode:stop] autorelease];
	}
	if (xmlStrEqual(stop->name, (xmlChar*)"VideoStop"))
	{
		VideoStop *videoStop = [[[VideoStop alloc] initWithStopNode:stop] autorelease];
		[videoStop setIsAudio:NO];
		return videoStop;
	}
	if (xmlStrEqual(stop->name, (xmlChar*)"AudioStop"))
	{
		VideoStop *videoStop = [[[VideoStop alloc] initWithStopNode:stop] autorelease];
		[videoStop setIsAudio:YES];
		return videoStop;
	}
	if (xmlStrEqual(stop->name, (xmlChar*)"WebStop"))
	{
		return [[[WebStop alloc] initWithStopNode:stop] autorelease];
	}
	return nil;
}

@end
