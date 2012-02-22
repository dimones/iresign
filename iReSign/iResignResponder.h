//
//  iResignResponder.h
//  iReSign
//
//  Created by Patrick Blitz on 1/15/12.
//  Copyright (c) 2012 Weptun GmbH. 
//

#import <Foundation/Foundation.h>

@protocol iResignResponder <NSObject>
- (void)showAlert:(NSString*)message;
- (void)setStatus:(NSString*)message;
-(void)reportFinished;
@end
