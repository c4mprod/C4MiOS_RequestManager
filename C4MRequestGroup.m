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
 * C4MiOS_RequestManager is distributed in the hope that it will be useful,
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
 
#import "C4MRequestGroup.h"
#import "JSONKit.h"
#import "C4MJSonEncoding.h"

@interface C4MRequestGroup(_Private)

// Private
- (NSMutableURLRequest *) getRequestFromRequestObject:(NSObject *)_requestObject;

@end

@implementation C4MRequestGroup

@synthesize mC4MRequests;
@synthesize mResponseHandler;
@synthesize mServerURLString;
@synthesize mAdditionalHttpHeaders;
@synthesize mTimeOutInterval;
@synthesize mHTTPMethod;
@synthesize mKeepWrapperArrayForSingleRequest;
@synthesize mQueryStringPrefixKeyword;

#pragma mark -
#pragma mark Init
//!  use for create an array of requests
- (id) initWithC4MRequestArray:(NSArray *)_c4mRequests withDelegate:(NSObject<JSonResponseHandler>*)_delegate withTargetURLString:(NSString *)_urlString withAdditionnalHTTPHeaders:(NSDictionary *)_additionalHttpHeaders httpMethod:(int)_HTTPMethod
{
    if ( self = [super init])
	{
        self.mC4MRequests = _c4mRequests;
        self.mResponseHandler = _delegate;
        self.mServerURLString = _urlString;
        self.mAdditionalHttpHeaders = _additionalHttpHeaders;
		self.mTimeOutInterval = kTimeOutIntervalDefault;
		self.mQueryStringPrefixKeyword = nil;
        self.mHTTPMethod = _HTTPMethod;
        self.mKeepWrapperArrayForSingleRequest = YES;
        mIsJSon = YES;
    }
	
	return self;
}

//! use for single request
- (id) initWithSingleC4MRequest:(C4MRequest *)_c4mRequest withDelegate:(NSObject<JSonResponseHandler>*)_delegate withTargetURLString:(NSString *)_urlString withAdditionnalHTTPHeaders:(NSDictionary *)_additionalHttpHeaders httpMethod:(int)_HTTPMethod
{
    if ( (self = [self initWithC4MRequestArray:[NSArray arrayWithObject:_c4mRequest] withDelegate:_delegate withTargetURLString:_urlString withAdditionnalHTTPHeaders:_additionalHttpHeaders httpMethod:_HTTPMethod]))
	{
        mIsJSon = _c4mRequest.isJSon;
        
        if ( mIsJSon == NO) {
            self.mKeepWrapperArrayForSingleRequest = NO;
            self.mHTTPMethod = _HTTPMethod;
        }
    }
	return self;
}

- (NSMutableURLRequest *) getNSMutableURLRequest
{                                                    
    if (mC4MRequests == nil || mServerURLString == nil || [mC4MRequests count] == 0)
	{
        return nil;
    }
    
    int request_count = [mC4MRequests count];
    
    NSObject *request_object;
    if (mKeepWrapperArrayForSingleRequest == NO && request_count == 1 ) {
        C4MRequest *first_request = [mC4MRequests objectAtIndex:0];
        request_object = first_request.mRequestDictionary;
    } else {
        // Wrap in an array as jSon is structured to allow several requests	on one call
        NSMutableArray *_wrapperArray = [NSMutableArray arrayWithCapacity:request_count];
        for ( C4MRequest* c4m_request in mC4MRequests)
        {
            // Non Json Requests will be ignored if there are several requests as this mode
            // is only for JSon grouping.
            if ( c4m_request.isJSon) {
                [_wrapperArray addObject:c4m_request.mRequestDictionary];    
            } else {
                NSLog(@"Non JSon Request was excluded from request group: %@", c4m_request.mRequestDictionary);
            }

        }
        request_object = _wrapperArray;
    }

    
        
    NSMutableURLRequest *request = [self getRequestFromRequestObject:request_object];  
    
    return request;
}

/**
 * Request Object can be either a NSArray or a NSDictionary
 */
- (NSMutableURLRequest *) getRequestFromRequestObject:(NSObject *)_requestObject 
{
    NSString *json_string;
    
    if (mIsJSon) {
        if([_requestObject isKindOfClass:[NSDictionary class]]) {
			json_string = [(NSDictionary*)_requestObject JSONString];
		} else if([_requestObject isKindOfClass:[NSArray class]]) {
			json_string = [(NSArray*)_requestObject JSONString];
        }
    } else {
        json_string = [NSString string];
    }

    
    
    C4MLog(@" --> _requestObject = %@", _requestObject);
    C4MLog(@"      json_string    = %@", json_string);
	json_string = [self applyCustomModificationsToJsonString:json_string];
    
    // get additonal params
    // This needs to be done BEFORE the URL encoding, the method must handle its
    // encoding if needed.
	NSDictionary* additional_params = [self getAdditionalRequestParameters:json_string];
    
	// encode JSon request parameters if needed (Get or Raw post)
    if (mHTTPMethod == HTTP_GET /*|| mQueryStringPrefixKeyword == nil*/) {
        json_string = [self encodeJSonString:json_string]; 	
    }
    
    
    // add base params for non json requests
	if (mIsJSon == NO) {
        if ([_requestObject isKindOfClass:[NSDictionary class]]) {
            NSString *separator = @"";
            //for ( NSString *key in [((NSDictionary *)_requestObject) allKeys]) {
            for ( int i=0; i < [((NSDictionary *)_requestObject) count]; i++) {
                NSString *key = [[((NSDictionary *)_requestObject) allKeys] objectAtIndex:i];
                if ( key != nil) {
                    NSString *value = [((NSDictionary *)_requestObject) valueForKey:key];
                    if (value != nil) {
                        if ( i > 0) {
                            separator = @"&";    
                        }
                        json_string = [json_string stringByAppendingFormat:@"%@%@=%@", separator, key, value];
                    }
                }
            }
        } else {
            NSLog(@"ERROR: _requestObject should be a dictionary: %@", _requestObject);
        }
    }	
    
	// add additional params to request if any.
    // This needs to be done AFTER the URL encoding, params should have their
    // own encoding if needed as some should not be encoded (signatures)
    if (additional_params != nil) {
        for ( NSString *key in [additional_params allKeys]) {
            if ( key != nil) {
                NSString *value = [additional_params valueForKey:key];
                if (value != nil) {
                        json_string = [json_string stringByAppendingFormat:@"&%@=%@", key, value];
                }
            }
        }
    }
    
    C4MLog(@"Sending json string: %@", json_string);
    
	NSURL *url;
	if (mHTTPMethod == HTTP_GET)
	{
        // Encoding is now done a few lines above using encodeJSonString
		// json_string = [json_string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *query_prefix = (mQueryStringPrefixKeyword != nil)?[NSString stringWithFormat:@"%@=",mQueryStringPrefixKeyword]:@"";
		if(![query_prefix isEqualToString:@""] || ![json_string isEqualToString:@""])
		{
			url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@%@",mServerURLString,query_prefix,json_string]];
		}
		else
		{
			url = [NSURL URLWithString:mServerURLString];
		}		
	}
	else
	{
		url = [NSURL URLWithString:mServerURLString];
	}


	
	
	// Perform Request
	
	//NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

	
	
	// ********* SET REQUEST TIMEOUT *********
	[request setTimeoutInterval:mTimeOutInterval];

	
	// ********* SET ADDITIONAL HEADER PARAMS *********
    if (mAdditionalHttpHeaders != nil)
    {
        for (NSString *header_key in [mAdditionalHttpHeaders allKeys])
		{
            NSString *header_value = [mAdditionalHttpHeaders valueForKey:header_key];
            [request setValue:header_value forHTTPHeaderField:header_key];
        }
    }
	
	
	// really needed?
	request = [self applyCustomModificationsToRequest:request withJsonString:json_string];
	
	
	
	
	if (mHTTPMethod == HTTP_GET)
	{
		
		[request setHTTPMethod:@"GET"];
        C4MLog(@"Sending GET request: %@", request);
	}
	else if (mHTTPMethod == HTTP_POST)
	{
		[request setHTTPMethod:@"POST"];
        if (mQueryStringPrefixKeyword != nil) {
			C4MLog(@"json post : %@",mQueryStringPrefixKeyword);
			json_string = [NSString stringWithFormat:@"%@=%@",mQueryStringPrefixKeyword,json_string];
		}
		NSData *body = [json_string dataUsingEncoding:NSUTF8StringEncoding];
		if (body != nil)
		{
			[request setHTTPBody:body];
		}
	}
    else if(mHTTPMethod == HTTP_PUT)
	{
		NSLog(@"PUT parameters : %@", json_string);
		
		[request setHTTPMethod:@"PUT"];
        if (mQueryStringPrefixKeyword != nil) 
		{			
			json_string = [NSString stringWithFormat:@"%@=%@",mQueryStringPrefixKeyword,json_string];
		}
		NSData *body = [json_string dataUsingEncoding:NSUTF8StringEncoding];
		if (body != nil)
		{
			[request setHTTPBody:body];
		}
	}
    
    //Displays HTTP Header
    //  NSDictionary * dicrequest = [request allHTTPHeaderFields];
    //  C4MLog(@"HTTP header for request:\n %@",dicrequest);
    //    
    //  C4MLog(@"[NSURLConnection canHandleRequest]: %@", ([NSURLConnection canHandleRequest:request]?@"YES":@"NO"));
    
    return request;
}

- (NSString *) applyCustomModificationsToJsonString:(NSString *)_jsonString
{
	return _jsonString;
}

- (NSMutableURLRequest *) applyCustomModificationsToRequest:(NSMutableURLRequest *) _request withJsonString:(NSString *)_jsonString
{
	return _request;
}

- (NSString*)encodeJSonString:(NSString *)_jsonString
{	
	_jsonString = [_jsonString urlEncodeUsingEncoding:NSUTF8StringEncoding];
	
	return _jsonString;
}


- (NSDictionary*) getAdditionalRequestParameters:(NSString*)_jsonString
{
	return nil;
}


#pragma mark -
#pragma mark Memory Management

- (void)dealloc
{
    [mC4MRequests release];
    [mResponseHandler release];
    [mServerURLString release];
	[mQueryStringPrefixKeyword release];
    [mAdditionalHttpHeaders release];
    [super dealloc];
}


@end
