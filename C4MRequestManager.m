/*******************************************************************************
 * This file is part of the C4MiOS_RequestManager project.
 * 
 * Copyright (c) 2012 C4M PROD.
 * 
 * C4MiOS_RequestManager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * C4MAndroidImageManager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with C4MiOS_RequestManager. If not, see <http://www.gnu.org/licenses/lgpl.html>.
 * 
 * Contributors:
 * C4M PROD - initial API and implementation
 ******************************************************************************/

#import "C4MRequestManager.h"

typedef enum {
	NetworkStatusIndeterminate,
	NetworkStatusNotReachable,
	NetworkStatusReachableViaWiFi,
	NetworkStatusReachableViaWWAN
} NetworkStatus;

@interface C4MRequestManager(_Private)

// Private
- (void) startProcessingRequestsIfNeeded;
- (void) processNextRequest;
- (id) init;

@end


@implementation C4MRequestManager

@synthesize mURLConnection;
@synthesize mReceivedData;
@synthesize processing;
@synthesize mTimeOutTimer;


static C4MRequestManager *	sharedRequestManager = nil;

+ (C4MRequestManager *)sharedRequestManager
{
	if (sharedRequestManager == nil)
	{
		sharedRequestManager = [[C4MRequestManager alloc] init];
    }
	
	return sharedRequestManager;
}

#pragma mark -
#pragma mark Init

- (id) init
{
    if ( (self = [super init]))
	{
        mExecutionIdentifierKeysStack = [NSMutableArray array];
        [mExecutionIdentifierKeysStack retain];
        
        mRequestGroupsByIdentifierKeys = [NSMutableDictionary dictionary];
        [mRequestGroupsByIdentifierKeys retain];
        
        self.mTimeOutTimer				= nil;
		
		mNetworkStatus = NetworkStatusIndeterminate;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityStateDidChange:) name:@"RKReachabilityStateChangedNotification" object:nil];
    }
	
	return self;
}

#pragma mark -
#pragma mark Asynchonous Request Methods
//! send the request to the server
/**
 *\param _requestGroup : the request group to send
 *\param _identifierKey : the identifier Key for identify what request parse the parser
 */
- (NSString*) performAsynchronousRequestsFromRequestGroup:(C4MRequestGroup *)_requestGroup withIdentifierKey:(NSString *)_identifierKey
{
    if (_requestGroup == nil)
	{
        return nil;
    }
    
    if (_identifierKey == nil)
	{
        _identifierKey = [_requestGroup description];
    }
    
    [mRequestGroupsByIdentifierKeys setObject:_requestGroup forKey:_identifierKey];
    [mExecutionIdentifierKeysStack addObject:_identifierKey];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self startProcessingRequestsIfNeeded];
	
	return _identifierKey;
}

- (void) startProcessingRequestsIfNeeded
{
    if ( !processing)
    {
        [self processNextRequest];
    }
}

- (void) processNextRequest
{
    @synchronized(mExecutionIdentifierKeysStack)
    {
        processing = YES;
        mIsCancelling = NO;
		
        if ( [mExecutionIdentifierKeysStack count] > 0)
		{
            mCurrentRequestIdentifier = (NSString *)[mExecutionIdentifierKeysStack objectAtIndex:0];
            C4MRequestGroup *currentRequestGroup = (C4MRequestGroup *)[mRequestGroupsByIdentifierKeys objectForKey:mCurrentRequestIdentifier];
			
			// if no network, do not even try to launch connection
			if (mNetworkStatus == NetworkStatusNotReachable)
			{
				C4MLog(@"*** no network - request cancelled");
				// Simulate no connection error
				[currentRequestGroup.mResponseHandler jsonRequestFailed:[NSError errorWithDomain:NSURLErrorDomain code:-1009 userInfo:nil] forRequestKey:mCurrentRequestIdentifier];
				
				[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
				[mRequestGroupsByIdentifierKeys removeObjectForKey:mCurrentRequestIdentifier];
				[mExecutionIdentifierKeysStack removeObject:mCurrentRequestIdentifier];
				
				[self processNextRequest];
				
				return;
			}
			
            self.mReceivedData = [NSMutableData data];
            [mURLConnection cancel];
            NSMutableURLRequest *request = [currentRequestGroup getNSMutableURLRequest];
            
            C4MLog(@"URL %@", [request URL]);
			C4MLog(@"http headers %@", [request allHTTPHeaderFields]);
			C4MLog(@"Methods HTTP : %@", [request HTTPMethod]);
			C4MLog(@"HTTP Body : %@", [request HTTPBody]);
            
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
			
            [self restartTimer];
            
            self.mURLConnection = connection;
            [connection release];
        } else
		{
            processing = NO;
        }

    }
}


//! cancel the send request
/**
 *\param _identifierKey : identifier of the request
 * use when the view pop, else the application receive a sigabrt signal
 */
- (void) cancelAsynchronousRequestWithIdentifierKey:(NSString *)_identifierKey
{
	if ([mCurrentRequestIdentifier isEqualToString:_identifierKey])
	{
		[mURLConnection cancel];
		[mRequestGroupsByIdentifierKeys removeObjectForKey:mCurrentRequestIdentifier];
		[mExecutionIdentifierKeysStack removeObject:mCurrentRequestIdentifier];
		[self processNextRequest];
		
		mIsCancelling = YES;
	}
	else
	{
		[mRequestGroupsByIdentifierKeys removeObjectForKey:_identifierKey];
		
		NSMutableArray *idToRemove = [NSMutableArray array];
		for (NSString *idKey in mExecutionIdentifierKeysStack)
		{
			if ([idKey isEqualToString:_identifierKey])
			{
				[idToRemove addObject:idKey];
			}
		}
		[mExecutionIdentifierKeysStack removeObjectsInArray:idToRemove];
	}
}

#pragma mark -
#pragma mark Connection Delegate Methods

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [mTimeOutTimer invalidate];
	self.mTimeOutTimer = nil;
    
	C4MLog(@"JSonQuerier connection failed -- %@", [error localizedDescription]);
	C4MLog(@"JSonQuerier code:%d  ------  domain:%@", [error code], [error domain]);
    
	if (!mIsCancelling)
	{
		C4MRequestGroup *currentRequestGroup = (C4MRequestGroup *)[mRequestGroupsByIdentifierKeys objectForKey:mCurrentRequestIdentifier];
		[currentRequestGroup.mResponseHandler jsonRequestFailed:error forRequestKey:mCurrentRequestIdentifier];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		[mRequestGroupsByIdentifierKeys removeObjectForKey:mCurrentRequestIdentifier];
		[mExecutionIdentifierKeysStack removeObject:mCurrentRequestIdentifier];
		[self processNextRequest];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	// TODO: Override this in your own implementation/subclass of C4MRequestManager if needed as this is
    // application dependent.
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //    NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *) response;
    //    NSDictionary * dicresponse = httpResponse.allHeaderFields ; 
    //    C4MLog(@"HTTP header for response:\n %@",dicresponse);
    
    
    if ([response respondsToSelector:@selector(statusCode)])
	{
		int statusCode = [((NSHTTPURLResponse *)response) statusCode];
		mCurrentRequestStatusCode = statusCode;
        
        //NSLog(@"fields=%lld", response.expectedContentLength);
		//NSLog(@" status code %i for  request %@", mCurrentRequestStatusCode, mCurrentRequestIdentifier);
	}
    
	[self restartTimer];
	
	[self.mReceivedData setLength:0];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[self restartTimer];
	
    /* Append the new data to the received data. */
	[self.mReceivedData appendData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    [mTimeOutTimer invalidate];
	self.mTimeOutTimer = nil;
    
	NSString *filesContent = [[NSString alloc] initWithData:mReceivedData encoding:NSUTF8StringEncoding];
	//C4MLog(@"JSonQuerier: JSON Response String: %@", filesContent);
    
	if(filesContent == nil)
	{
		if([mReceivedData length] > 0)
		{
			NSLog(@"!!!WARNING!!! Wrong encoding format");
		}
		filesContent = [[NSString alloc] initWithData:mReceivedData encoding:NSISOLatin1StringEncoding];
	}
	    
    C4MRequestGroup *currentRequestGroup = (C4MRequestGroup *)[mRequestGroupsByIdentifierKeys objectForKey:mCurrentRequestIdentifier];
    [currentRequestGroup.mResponseHandler parseJSonResponse:filesContent forRequestKey:mCurrentRequestIdentifier withStatusCode:mCurrentRequestStatusCode];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[filesContent release];
	
    [mRequestGroupsByIdentifierKeys removeObjectForKey:mCurrentRequestIdentifier];
    [mExecutionIdentifierKeysStack removeObject:mCurrentRequestIdentifier];
    [self processNextRequest];
    
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [mURLConnection release];
    [mReceivedData release];
    [mExecutionIdentifierKeysStack release];
    [mRequestGroupsByIdentifierKeys release];
    [sharedRequestManager release];
    self.mTimeOutTimer = nil;
    [super dealloc];
}

#pragma mark -
#pragma mark Timer Methods


- (void)timerDidFire:(NSTimer*)_TimeOutTimer
{
	[mURLConnection cancel];
	[mTimeOutTimer invalidate];
	self.mTimeOutTimer = nil;
	
	[self connection:nil didFailWithError:nil];
}


- (void)restartTimer
{
	C4MRequestGroup *currentRequestGroup = (C4MRequestGroup *)[mRequestGroupsByIdentifierKeys objectForKey:mCurrentRequestIdentifier];
	
	if (currentRequestGroup != nil)
	{	
		// POST Timeout is 240 sec min.
		if(currentRequestGroup.mHTTPMethod == HTTP_POST)
		{
			if(currentRequestGroup.mTimeOutInterval < 240) 
			{
				[mTimeOutTimer invalidate];
				self.mTimeOutTimer = [NSTimer scheduledTimerWithTimeInterval:currentRequestGroup.mTimeOutInterval target:self selector:@selector(timerDidFire:) userInfo:nil repeats:NO];
			}
		}
	}
}



#pragma mark -
#pragma mark Synchronous Requests Static Methods

+ (NSString *) performSynchronousRequestsForC4MRequestGroup:(C4MRequestGroup *)_requestGroup
{
    
    NSMutableURLRequest *request = [_requestGroup getNSMutableURLRequest];
    NSURLResponse *response;
    NSError *error;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
	NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	//C4MLog(@"JSonQuerier: JSON Response String: %@", content);
    NSString *result = [NSString stringWithString:content];
    [content release];
	return result;
}

#pragma mark - Reachability
- (void)reachabilityStateDidChange:(NSNotification*)_notification
{
	NetworkStatus oldStatus = mNetworkStatus;
	
	mNetworkStatus = [(NSNumber*)[[_notification userInfo] objectForKey:@"status"] intValue];
	
	C4MLog(@"*** new network status = %d", mNetworkStatus);
	
	if ( mNetworkStatus >= NetworkStatusReachableViaWiFi && (oldStatus == NetworkStatusNotReachable || oldStatus == NetworkStatusIndeterminate) )
	{
		[self startProcessingRequestsIfNeeded];
	}
}


@end
