//
//  IResignLogic.h
//  iReSign
//
//  Created by Patrick Blitz on 1/15/12.
//  Copyright (c) 2012 Weptun GmbH. 
//

#import <Foundation/Foundation.h>
#import "iResignResponder.h"
@interface IResignLogic : NSObject {
    NSTask *unzipTask;
    NSTask *provisioningTask;
    NSTask *codesignTask;
    NSTask *verifyTask;
    NSTask *zipTask;
    NSString *appPath;
    NSString *workingPath;
    NSString *appName;
    NSString *fileName;
    
    NSString *codesigningResult;
    NSString *verificationResult;
    
    
    NSString *ipaPath;
    NSString *provisioningPath;
    NSString *codeSigningName;
    
    NSObject<iResignResponder>* callback;
}
@property (nonatomic, retain) NSString *workingPath;
@property (nonatomic, retain) NSObject<iResignResponder> *callback;
@property (nonatomic, retain) NSString *ipaPath;
@property (nonatomic, retain) NSString *provisioningPath;
@property (nonatomic, retain) NSString *codeSigningName;
@property BOOL verbose;


- (id)init:(id<iResignResponder>)aCallback;

-(void)startResigningTask;

@end
