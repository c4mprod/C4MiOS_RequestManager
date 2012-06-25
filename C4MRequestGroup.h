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

#import <Foundation/Foundation.h>
#import "JSonResponseHandler.h"
#import "C4MRequest.h"

#define kJsonAnswerKeyWord			@"answer"

#define kTimeOutIntervalDefault		5


enum HTTPMethod {
	HTTP_GET,
	HTTP_POST,
	HTTP_PUT,
	HTTP_DELETE
};



@interface C4MRequestGroup : NSObject
{
    NSArray                         *mC4MRequests;
    NSObject<JSonResponseHandler>   *mResponseHandler;
    NSString                        *mServerURLString;
	NSString                        *mQueryStringPrefixKeyword;
    NSDictionary                    *mAdditionalHttpHeaders;
	
	int								mHTTPMethod;
    BOOL							mKeepWrapperArrayForSingleRequest;
    BOOL                            mIsJSon;
	NSInteger						mTimeOutInterval;
}
@property (nonatomic, retain) NSArray							*mC4MRequests;
@property (nonatomic, retain) NSObject<JSonResponseHandler>		*mResponseHandler;
@property (nonatomic, retain) NSString							*mServerURLString;
@property (nonatomic, retain) NSString							*mQueryStringPrefixKeyword;
@property (nonatomic, retain) NSDictionary						*mAdditionalHttpHeaders;
@property (nonatomic) int										mHTTPMethod;
@property (nonatomic) BOOL										mKeepWrapperArrayForSingleRequest;
@property (nonatomic) NSInteger									mTimeOutInterval;

- (id) initWithC4MRequestArray:(NSArray *)_c4mRequests withDelegate:(NSObject<JSonResponseHandler>*)_delegate withTargetURLString:(NSString *)_urlString withAdditionnalHTTPHeaders:(NSDictionary *)_additionalHttpHeaders httpMethod:(int)_HTTPMethod;
- (id) initWithSingleC4MRequest:(C4MRequest *)_c4mRequest withDelegate:(NSObject<JSonResponseHandler>*)_delegate withTargetURLString:(NSString *)_urlString withAdditionnalHTTPHeaders:(NSDictionary *)_additionalHttpHeaders httpMethod:(int)_HTTPMethod;

- (NSMutableURLRequest *) getNSMutableURLRequest;
- (NSString *) applyCustomModificationsToJsonString:(NSString *)_jsonString;
- (NSMutableURLRequest *) applyCustomModificationsToRequest:(NSMutableURLRequest *) _request withJsonString:(NSString *)_jsonString;
- (NSDictionary*) getAdditionalRequestParameters:(NSString*)_jsonString;
- (NSString*)encodeJSonString:(NSString *)_jsonString;

@end
