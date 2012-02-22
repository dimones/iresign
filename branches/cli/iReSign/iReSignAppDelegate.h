//
//  iReSignAppDelegate.h
//  iReSign
//
//  Created by Maciej Swic on 2011-05-16.
//

#import <Cocoa/Cocoa.h>
#import "iResignResponder.h"
#import "IResignLogic.h"

@interface iReSignAppDelegate : NSObject <NSApplicationDelegate,iResignResponder> {
@private
    NSWindow *window;
    
    NSUserDefaults *defaults;
    
    
    IBOutlet NSTextField *pathField;
    IBOutlet NSTextField *provisioningPathField;
    IBOutlet NSTextField *certField;
    IBOutlet NSButton    *browseButton;
    IBOutlet NSButton    *provisioningBrowseButton;
    IBOutlet NSButton    *resignButton;
    IBOutlet NSTextField *statusLabel;
    IBOutlet NSProgressIndicator *flurry;
    
    NSString *originalIpaPath;
    IResignLogic * resignLogic;
    
}

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic,retain)     IResignLogic * resignLogic;

- (IBAction)resign:(id)sender;
- (IBAction)browse:(id)sender;
- (IBAction)provisioningBrowse:(id)sender;
- (IBAction)showHelp:(id)sender;


- (void)disableControls;
- (void)enableControls;
- (void)resizeWindow:(int)newHeight;


@end
