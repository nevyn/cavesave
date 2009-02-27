//
//  CaveSaver.m
//  CaveSave
//
//  Created by Joachim Bengtsson on 2009-02-27.
//  Copyright 2009 Third Cog Software. All rights reserved.
//

#import "CaveSaver.h"


@implementation CaveSaver
-(void)awakeFromNib;
{
  [self saveCaves:self];
}

-(IBAction)saveCaves:(id)sender;
{
  NSOpenPanel *openPanel = [[NSOpenPanel openPanel] retain];
  
  NSArray *fileTypes = [NSArray arrayWithObjects:@"dat",nil];
  
  [openPanel setTitle:@"Locate your Profile.dat from your Windows installation of Doukutsu"];
  [openPanel setPrompt:@"Transfer to Mac Doukutsu"];
  
  [openPanel beginForDirectory:nil
                          file:@"Profile.dat"
                         types:fileTypes
              modelessDelegate:self
                didEndSelector:@selector(profilePanelDidEnd:returnCode:contextInfo:)
                   contextInfo:nil];
  
}
-(void)profilePanelDidEnd:(NSOpenPanel*)sheet
               returnCode:(int)returnCode
              contextInfo:(void*)contextInfo;
{
  if(returnCode == NSCancelButton)
    [NSApp terminate:self];
  
  NSString *path = [sheet filename];
  
  NSInteger ret = NSRunAlertPanel(@"This will delete your Mac save games!", @"This will irrevocably delete your Doukutsu/Cave Story save games in Mac OS, and replace them with the Windows save games. This cannot be undone. Are you sure you want to continue?", 
                  @"Keep my Mac saves",
                  @"Replace Mac saves with Windows saves",  nil);
  if(ret == NSAlertDefaultReturn)
    [NSApp terminate:self];
  
  if( ! [[path lastPathComponent] isEqual:@"Profile.dat"] ) {
    ret = NSRunAlertPanel(@"Not Profile.dat?", @"Hey, the file you opened isn't called Profile.dat. I think you might've selected the wrong file. Are you sure you want to continue?", @"Stop", @"Continue", nil);
    if(ret == NSAlertDefaultReturn)
      [NSApp terminate:self];
  }
  
  NSError *failure;
  NSData *profileDat = [NSData dataWithContentsOfFile:path options:0 error:&failure];
  if( ! profileDat) {
    NSRunCriticalAlertPanel(@"Couldn't read Profile.dat", @"The save game file couldn't be read because %@\nSorry.", @"Bummer", nil, nil, [failure localizedDescription]);
    [NSApp terminate:self];
  }
  
  NSString *prefsPath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Preferences"];
  NSString *douPrefs = [prefsPath stringByAppendingPathComponent:@"com.nakiwo.Doukutsu.plist"];
  NSMutableDictionary *settings = [NSMutableDictionary dictionaryWithContentsOfFile:douPrefs];
  NSString *backupName = @"com.nakiwo.Doukutsu.backup.plist";
  if(!settings)
    settings = [NSMutableDictionary dictionary];
  else {
    NSString *backupPath = [prefsPath stringByAppendingPathComponent:backupName];
    [[NSFileManager defaultManager] moveItemAtPath:douPrefs toPath:backupPath error:nil];
  }
  
  [settings setObject:profileDat forKey:@"Profile.dat"];
  
  BOOL success = [settings writeToFile:douPrefs atomically:YES];
  if(!success) {
    NSRunCriticalAlertPanel(@"Couldn't save Mac save file", @"The save games couldn't be written to your Mac settings. Sorry.", @"Bummer", nil, nil);
    [NSApp terminate:self];
  }
  
  NSRunAlertPanel(@"Save games transferred", @"Your save games were successfully transferred from %@ to %@. You can now continue playing in Mac OS.\n\nI must confess, I lied. I backed up your old Mac settings. If you want to undo the transfer, remove the file %@, and remove '.backup' from the file '%@' in the same folder.", @"Woo!", nil, nil, path, douPrefs, douPrefs, backupName);
  [NSApp terminate:self];
  
}
@end
