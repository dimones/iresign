//
//  IResignLogic.m
//  iReSign
//
//  Created by Patrick Blitz on 1/15/12.
//  Copyright (c) 2012 Weptun GmbH. 
//  Adapted from previous code of the iResign Project
//

#import "IResignLogic.h"

@interface IResignLogic (pivate)
    - (void)checkUnzip:(NSTimer *)timer;
    - (void)doProvisioning;
    - (void)checkProvisioning:(NSTimer *)timer;
    - (void)doCodeSigning;
    - (void)checkCodesigning:(NSTimer *)timer;
    - (void)doVerifySignature;
    - (void)checkVerificationProcess:(NSTimer *)timer;
    - (void)doZip;
    - (void)checkZip:(NSTimer *)timer;
    -(void)log:(NSString *)format, ... ;
-(NSString*) checkOrCreateResourceRules ;
@end

@implementation IResignLogic

- (id)init:(id<iResignResponder>)aCallback {
    self = [super init];
    if (self) {
        self.callback=aCallback;
        self.verbose=TRUE;
    }
    return self;
}

-(void)dealloc
{
    self.callback=nil;
}


-(void)setStatus:(NSString*)status {
    if (self.callback) {
        [self.callback setStatus:status];
    }
}

-(void)showAlert:(NSString*)alert {
    if (self.callback) {
        [self.callback showAlert:alert];
    }
}

-(void)startResigningTask
{
    if (!self.ipaPath && ((self.provisioningPath && self.codeSigningName) || !self.provisioningPath)) {
        [self showAlert:@"no values given!"];
    }
    codesigningResult = nil;
    verificationResult = nil;
    workingPath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"com.appulize.iresign"] retain];
    if (self.verbose) {
        [self log:@"Setting up working directory in %@",workingPath];
    }
    [self setStatus:@"Setting up working directory"];
    
    [[NSFileManager defaultManager] removeItemAtPath:workingPath error:nil];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:workingPath withIntermediateDirectories:TRUE attributes:nil error:nil];
    
    if (self.ipaPath && [self.ipaPath length] > 0) {
        if (self.verbose) {
        [self log:@"Unzipping %@",self.ipaPath];
        }
        [self setStatus:@"Extracting original app"];
    }
    
    unzipTask = [[NSTask alloc] init];
    [unzipTask setLaunchPath:@"/usr/bin/unzip"];
    [unzipTask setArguments:[NSArray arrayWithObjects:@"-q", self.ipaPath, @"-d", workingPath, nil]];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkUnzip:) userInfo:nil repeats:TRUE];
    
    [unzipTask launch];
}

- (void)checkUnzip:(NSTimer *)timer {
    if ([unzipTask isRunning] == 0) {
        [timer invalidate];
        [unzipTask release];
        unzipTask = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:[workingPath stringByAppendingPathComponent:@"Payload"]]) {
//            if (self.verbose) {
            [self log:@"Unzipping done"];
            [self setStatus:@"Original app extracted"];
            if ([self.provisioningPath isEqualTo:@""]) {
                [self doCodeSigning];
            } else {
                [self doProvisioning];
            }
        } else {
            [self showAlert:@"Unzip failed"];
        }
    }
}






- (void)doProvisioning {
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:@"Payload"] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            appPath = [[workingPath stringByAppendingPathComponent:@"Payload"] stringByAppendingPathComponent:file];
            if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
            [self log:@"Found embedded.mobileprovision, deleting."];
                [[NSFileManager defaultManager] removeItemAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] error:nil];
            }
            break;
        }
    }
    
    NSString *targetPath = [appPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    
    provisioningTask = [[NSTask alloc] init];
    [provisioningTask setLaunchPath:@"/bin/cp"];
    [provisioningTask setArguments:[NSArray arrayWithObjects:self.provisioningPath, targetPath, nil]];
    
    [provisioningTask launch];
    
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkProvisioning:) userInfo:nil repeats:TRUE];
}

- (void)checkProvisioning:(NSTimer *)timer {
    if ([provisioningTask isRunning] == 0) {
        [timer invalidate];
        [provisioningTask release];
        provisioningTask = nil;
        
        NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:@"Payload"] error:nil];
        
        for (NSString *file in dirContents) {
            if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
                appPath = [[workingPath stringByAppendingPathComponent:@"Payload"] stringByAppendingPathComponent:file];
                if ([[NSFileManager defaultManager] fileExistsAtPath:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"]]) {
                    
                    BOOL identifierOK = FALSE;
                    NSString *identifierInProvisioning = @"";
                    
                    NSString *embeddedProvisioning = [NSString stringWithContentsOfFile:[appPath stringByAppendingPathComponent:@"embedded.mobileprovision"] encoding:NSASCIIStringEncoding error:nil];
                    NSArray* embeddedProvisioningLines = [embeddedProvisioning componentsSeparatedByCharactersInSet:
                                                          [NSCharacterSet newlineCharacterSet]];
                    
                    for (int i = 0; i <= [embeddedProvisioningLines count]; i++) {
                        if ([[embeddedProvisioningLines objectAtIndex:i] rangeOfString:@"application-identifier"].location != NSNotFound) {
                            
                            NSInteger fromPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"<string>"].location + 8;
                            
                            NSInteger toPosition = [[embeddedProvisioningLines objectAtIndex:i+1] rangeOfString:@"</string>"].location;
                            
                            NSRange range;
                            range.location = fromPosition;
                            range.length = toPosition-fromPosition;
                            
                            NSString *fullIdentifier = [[embeddedProvisioningLines objectAtIndex:i+1] substringWithRange:range];
                            
                            NSArray *identifierComponents = [fullIdentifier componentsSeparatedByString:@"."];
                            
                            if ([[identifierComponents lastObject] isEqualTo:@"*"]) {
                                identifierOK = TRUE;
                            }
                            
                            for (int i = 1; i < [identifierComponents count]; i++) {
                                identifierInProvisioning = [identifierInProvisioning stringByAppendingString:[identifierComponents objectAtIndex:i]];
                                if (i < [identifierComponents count]-1) {
                                    identifierInProvisioning = [identifierInProvisioning stringByAppendingString:@"."];
                                }
                            }
                            break;
                        }
                    }
                    
            [self log:@"Mobileprovision identifier: %@",identifierInProvisioning];
                    
                    NSString *infoPlist = [NSString stringWithContentsOfFile:[appPath stringByAppendingPathComponent:@"Info.plist"] encoding:NSASCIIStringEncoding error:nil];
                    if ([infoPlist rangeOfString:identifierInProvisioning].location != NSNotFound) {
            [self log:@"Identifiers match"];
                        identifierOK = TRUE;
                    }
                    
                    if (identifierOK) {
            [self log:@"Provisioning completed."];
                        [self setStatus:@"Provisioning completed"];
                        [self doCodeSigning];
                    } else {
                        [self showAlert:@"Product identifiers don't match"];
                    }
                } else {
                    [self showAlert:@"Provisioning failed"];
                }
                break;
            }
        }
    }
}



- (void)doCodeSigning {
    appPath = nil;
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[workingPath stringByAppendingPathComponent:@"Payload"] error:nil];
    
    for (NSString *file in dirContents) {
        if ([[[file pathExtension] lowercaseString] isEqualToString:@"app"]) {
            appPath = [[workingPath stringByAppendingPathComponent:@"Payload"] stringByAppendingPathComponent:file];
            [self log:@"Found %@",appPath];
            appName = [file retain];
            [self setStatus:[NSString stringWithFormat:@"Codesigning %@",file]];
            break;
        }
    }
    
    if (appPath) {
        NSString* resourceRulesPath = [self checkOrCreateResourceRules];
        NSString *resourceRulesArgument = [NSString stringWithFormat:@"--resource-rules=%@",resourceRulesPath];
        codesignTask = [[NSTask alloc] init];
        [codesignTask setLaunchPath:@"/usr/bin/codesign"];
        [codesignTask setArguments:[NSArray arrayWithObjects:@"-fs", self.codeSigningName, resourceRulesArgument, appPath, nil]];
                    [self log:@"Starting codesigning with task: %@",[codesignTask arguments]];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkCodesigning:) userInfo:nil repeats:TRUE];
        
        [appPath retain];
        
        NSPipe *pipe=[NSPipe pipe];
        [codesignTask setStandardOutput:pipe];
        [codesignTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [codesignTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchCodesigning:)
                                 toTarget:self withObject:handle];
    }
}

- (void)watchCodesigning:(NSFileHandle*)streamHandle {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    
    codesigningResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    
    [pool release];
}



- (void)checkCodesigning:(NSTimer *)timer {
    if ([codesignTask isRunning] == 0) {
        [timer invalidate];
        [codesignTask release];
        codesignTask = nil;
        [self log:@"Codesigning done"];
        [self setStatus:@"Codesigning completed"];
        [self doVerifySignature];
    }
}




- (void)doVerifySignature {
    if (appPath) {
        verifyTask = [[NSTask alloc] init];
        [verifyTask setLaunchPath:@"/usr/bin/codesign"];
        [verifyTask setArguments:[NSArray arrayWithObjects:@"-v", appPath, nil]];
        [self log:@"Starting Verify with task: %@",[verifyTask arguments]];
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkVerificationProcess:) userInfo:nil repeats:TRUE];
        
        [self log:@"Verifying %@",appPath];
        [self setStatus:[NSString stringWithFormat:@"Verifying %@",appName]];
        
        NSPipe *pipe=[NSPipe pipe];
        [verifyTask setStandardOutput:pipe];
        [verifyTask setStandardError:pipe];
        NSFileHandle *handle=[pipe fileHandleForReading];
        
        [verifyTask launch];
        
        [NSThread detachNewThreadSelector:@selector(watchVerificationProcess:)
                                 toTarget:self withObject:handle];
    }
}

- (void)watchVerificationProcess:(NSFileHandle*)streamHandle {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    
    verificationResult = [[NSString alloc] initWithData:[streamHandle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    
    [pool release];
}



- (void)checkVerificationProcess:(NSTimer *)timer {
    if ([verifyTask isRunning] == 0) {
        [timer invalidate];
        [verifyTask release];
        verifyTask = nil;
        if ([verificationResult length] == 0) {
        [self log:@"Verification done"];
            [self setStatus:@"Verification completed"];
            [self doZip];
        } else {
            NSString *errors = [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
            [self showAlert:[NSString stringWithFormat:@"Signing failed: %@",errors]];
        }
    }
}




- (void)doZip {
    if (appPath) {
        NSArray *destinationPathComponents = [self.ipaPath pathComponents];
        NSString *destinationPath = @"";
        
        for (int i = 0; i < ([destinationPathComponents count]-1); i++) {
            destinationPath = [destinationPath stringByAppendingPathComponent:[destinationPathComponents objectAtIndex:i]];
        }
        
        fileName = [self.ipaPath lastPathComponent];
        fileName = [fileName substringToIndex:[fileName length]-4];
        fileName = [fileName stringByAppendingString:@"-resigned"];
        fileName = [fileName stringByAppendingPathExtension:@"ipa"];
        
        destinationPath = [destinationPath stringByAppendingPathComponent:fileName];
        
        [self log:@"Dest: %@",destinationPath];
        
        zipTask = [[NSTask alloc] init];
        [zipTask setLaunchPath:@"/usr/bin/zip"];
        [zipTask setCurrentDirectoryPath:workingPath];
        [zipTask setArguments:[NSArray arrayWithObjects:@"-qr", destinationPath, @".", nil]];
		
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(checkZip:) userInfo:nil repeats:TRUE];
        
        [self log:@"Zipping %@", destinationPath];
        [self setStatus:[NSString stringWithFormat:@"Saving %@",fileName]];
        
        [fileName retain];
        [zipTask launch];
    }
}


- (void)checkZip:(NSTimer *)timer {
    if ([zipTask isRunning] == 0) {
        [timer invalidate];
        [zipTask release];
        zipTask = nil;
        [self log:@"Zipping done"];
        [self setStatus:[NSString stringWithFormat:@"Saved %@",fileName]];
        
        [[NSFileManager defaultManager] removeItemAtPath:workingPath error:nil];
        
        [appPath release];
        [workingPath release];
        NSString *result = [[codesigningResult stringByAppendingString:@"\n\n"] stringByAppendingString:verificationResult];
        [self log:@"Codesigning result: %@",result];
        [self.callback reportFinished];
    }
}

-(NSString*) checkOrCreateResourceRules {
    NSString *resourceRulesPath = [[NSBundle mainBundle] pathForResource:@"ResourceRules" ofType:@"plist"];
    if (!resourceRulesPath) {
        resourceRulesPath=[workingPath stringByAppendingPathComponent:@"ResourceRules.plist"];
        NSMutableDictionary * main = [NSMutableDictionary dictionaryWithCapacity:1];
        NSMutableDictionary * rules = [NSMutableDictionary dictionaryWithCapacity:3];        
        NSMutableDictionary * info = [NSMutableDictionary dictionaryWithCapacity:3];
        [info setValue:[NSNumber numberWithBool:YES] forKey:@"omit"];
        [info setValue:[NSNumber numberWithInt:10] forKey:@"weight"];
        NSMutableDictionary * resource = [NSMutableDictionary dictionaryWithCapacity:3];
        [resource setValue:[NSNumber numberWithBool:YES] forKey:@"omit"];
        [resource setValue:[NSNumber numberWithInt:100] forKey:@"weight"];
        [rules setValue:info forKey:@"Info.plist"];
        [rules setValue:resource forKey:@"ResourceRules.plist"];
        [rules setValue:[NSNumber numberWithBool:YES] forKey:@".*"];
        [main setValue:rules forKey:@"rules"];
                           BOOL result=[main writeToFile:resourceRulesPath atomically:YES];
                           if (result) {
                            //        [self log:@"we successfully wrote the resourceRulesPath to %@",resourceRulesPath];
                               
                           } else {
                               [self showAlert:[NSString stringWithFormat:@"we could not wirte resourceRulesPath to %@",resourceRulesPath]];

                               exit(0);
                           }
        
    }
    return resourceRulesPath;
    
}

#pragma mark - logging 

    
-(void)log:(NSString *)format, ... 
    {
        if (self.verbose) {
            va_list argList;
            va_start(argList, format);
            NSLogv(format,argList);
        }
        
    }

#pragma mark - synthesizes

@synthesize callback;
@synthesize workingPath;
@synthesize ipaPath;
@synthesize provisioningPath;
@synthesize codeSigningName;
@synthesize verbose;
@end
