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

#import <Foundation/Foundation.h>

#define kJsonRequestKeyWord			@"request"

@interface C4MRequest : NSObject
{
    NSMutableDictionary*    mRequestDictionary;
    BOOL                    mIsJSon;
}

@property (nonatomic, retain) NSMutableDictionary*  mRequestDictionary;
@property (nonatomic)         BOOL                  isJSon;

- (id) initWithRequestKeyword:(NSString *)_requestKeyWord andParams:(NSDictionary *)_params;
- (id) initWithDictionary:(NSDictionary *)_dic;
- (id) initWithParams:(NSDictionary *)_params isJSon:(BOOL)_isJSon;



@end
