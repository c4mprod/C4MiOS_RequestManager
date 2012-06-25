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

#import "C4MRequest.h"

@implementation C4MRequest

@synthesize mRequestDictionary;
@synthesize isJSon = mIsJson;

#pragma mark -
#pragma mark Init
//! create the request for the request group
/**
 *\param _requestKeyWord : name of the request - example, deactivate
 *\param _params : NSDictionary correspondind to the parameters of the request
 */
- (id) initWithRequestKeyword:(NSString *)_requestKeyWord andParams:(NSDictionary *)_params
{
    if ( self = [super init]) {
        C4MLog(@"Init C4MRequest witk keyword %@ with params:%@", _requestKeyWord, _params);
        if ( _requestKeyWord == nil) {
            return [self initWithDictionary:_params];
        }
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:_params];
        [dic setObject:_requestKeyWord forKey:kJsonRequestKeyWord];
        self.mRequestDictionary = dic;
        self.isJSon = YES;
    }
	
	return self;
}

//! use by initWithRequestKeyword
- (id) initWithDictionary:(NSDictionary *)_dic
{
    if ( self = [super init]) {
        C4MLog(@"Init C4MRequest witk dictionary:%@", _dic);
        self.mRequestDictionary = [NSMutableDictionary dictionaryWithDictionary:_dic];
        self.isJSon = YES;
    }
	
	return self;
}

- (id) initWithParams:(NSDictionary *)_params isJSon:(BOOL)_isJSon {
    if (self = [self initWithDictionary:_params]) {
        self.isJSon = _isJSon;
    }
    
    return self;
}

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [mRequestDictionary release];
    [super dealloc];
}


@end
