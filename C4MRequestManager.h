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
#import <UIKit/UIKit.h>
#import "C4MRequest.h"
#import "JSonResponseHandler.h"
#import "C4MRequestGroup.h"

@interface C4MRequestManager : NSObject
{
    NSURLConnection					*mURLConnection;
    NSMutableData					*mReceivedData;
    
    NSMutableArray                  *mExecutionIdentifierKeysStack;
    NSMutableDictionary             *mRequestGroupsByIdentifierKeys;

    NSString                        *mCurrentRequestIdentifier;
    BOOL                            processing;
	
	BOOL							mIsCancelling;
    
    int								mCurrentRequestStatusCode;
    NSTimer*						mTimeOutTimer;
	
	int								mNetworkStatus;
}

@property (nonatomic, retain) NSTimer*				mTimeOutTimer;
@property (nonatomic, retain) NSURLConnection       *mURLConnection;
@property (nonatomic, retain) NSMutableData         *mReceivedData;

@property (nonatomic)         BOOL                  processing;

- (void)timerDidFire:(NSTimer*)_TimeOutTimer;
- (void)restartTimer;

- (NSString *) performAsynchronousRequestsFromRequestGroup:(C4MRequestGroup *)_requestGroup withIdentifierKey:(NSString *)_identifierKey;
- (void) cancelAsynchronousRequestWithIdentifierKey:(NSString *)_identifierKey;

+ (C4MRequestManager *)sharedRequestManager;
+ (NSString *) performSynchronousRequestsForC4MRequestGroup:(C4MRequestGroup *)_requestGroup;

@end