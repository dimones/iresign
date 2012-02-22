//
//  iResignCLIDelegate.m
//  iReSign
//
//  Created by Patrick Blitz on 1/15/12.
//  Copyright (c) 2012 Weptun GmbH. 
//

#import "iResignCLIDelegate.h"

@implementation iResignCLIDelegate


-(void)applicationDidFinishLaunching:(NSNotification *)notification
{
//    NSLog(@"starting resigning!");
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/zip"]) {
        NSLog(@"This app cannot run without the zip utility present at /usr/bin/zip");
        exit(0);
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/unzip"]) {
        NSLog(@"This app cannot run without the unzip utility present at /usr/bin/unzip");
        exit(0);
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/usr/bin/codesign"]) {
        NSLog( @"This app cannot run without the codesign utility present at /usr/bin/codesign");
        exit(0);
    }
    
    self.resignLogic=[[IResignLogic alloc] init:self];
    self.resignLogic.ipaPath=self.ipaPath;
    self.resignLogic.provisioningPath=self.provisioningPath;
    self.resignLogic.codeSigningName=self.codeSigningName;
    self.resignLogic.verbose=self.verbose;
    
    [self.resignLogic startResigningTask];
}

-(void)setStatus:(NSString *)message
{
    NSLog(@"STATUS: %@",message);
}

-(void)showAlert:(NSString *)message
{
    NSLog(@"WARNING: %@",message);
}
-(void) reportFinished  {
    NSLog(@"The resigning process was completed successfully"); 
    exit(0);   
}

@synthesize ipaPath;
@synthesize provisioningPath;
@synthesize codeSigningName;
@synthesize resignLogic;
@synthesize verbose;
@end
