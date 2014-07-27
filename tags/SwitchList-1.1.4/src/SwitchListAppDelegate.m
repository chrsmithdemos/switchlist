//
//  SwitchListAppDelegate.m
//  SwitchList
//
//  Created by Robert Bowdidge on 9/17/05.
//
// Copyright (c)2005 Robert Bowdidge,
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
// OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
// LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
// OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
// SUCH DAMAGE.

#import "SwitchListAppDelegate.h"

#import "SwitchListDocument.h"

#import "CarReport.h"
#import "CargoReport.h"
#import "GlobalPreferences.h"
#import "HTMLSwitchListWindowController.h"
#import "HTMLSwitchlistRenderer.h"
#import "IndustryReport.h"
#import "KaufmanSwitchListView.h"
#import "NSFileManager+DirectoryLocations.h"
#import "PICLReport.h"
#import "ReservedCarReport.h"
#import "SouthernPacificSwitchListView.h"
#import "SwitchListReport.h"
#import "SwitchListView.h"
#import "WebServerDelegate.h"
#import "YardReport.h"

@implementation MyOutlineDelegate
// Creates a new MyOutlineViewController, using the pointer to the
// appDelegate to retrieve information about current selections.
- (id) initWithAppDelegate: (SwitchListAppDelegate*) appDelegate withOutlineView: (NSOutlineView*) view {
	[super init];
	// We're retained by appDelegate.
	appDelegate_ = appDelegate;
	problemsOutlineView_ = [view retain];
	return self;
}

- (void) dealloc {
	[problemsOutlineView_ release];
	[super dealloc];
}

- (NSString*) allProblemText {
	NSMutableString *fullString = [NSMutableString string];
	for (NSString *problem in [appDelegate_ problems]) {
		[fullString appendFormat: @"%@\n", problem];
    }
	return fullString;
}

// Copies the selected problems to the clipboard as strings, or all problems if
// none are selected.
- (IBAction) copy: (id) sender {
	// TODO(bowdidge): NSPasteboardItem is not available in 10.5, so this code just fails silently.
	NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	[pboard clearContents];
	NSPasteboardItem *pasteboardItem = [[[NSPasteboardItem alloc] init] autorelease];
	NSString *selectedString = [self selectedProblemText];
	if (selectedString == nil) {
		selectedString = [self allProblemText];
	}
	[pasteboardItem setString: selectedString forType: NSPasteboardTypeString];
	[pboard writeObjects: [NSArray arrayWithObject: pasteboardItem]];
}

// Print the Problems view's list of problems.  All problems are always printed.
- (IBAction) printDocument: (id) sender {
	// set printing properties
	NSPrintInfo *myPrintInfo = [NSPrintInfo sharedPrintInfo];
	[myPrintInfo setHorizontalPagination:NSFitPagination];
	[myPrintInfo setHorizontallyCentered:NO];
	[myPrintInfo setVerticallyCentered:NO];
	[myPrintInfo setLeftMargin:72.0];
	[myPrintInfo setRightMargin:72.0];
	[myPrintInfo setTopMargin:72.0];
	[myPrintInfo setBottomMargin:90.0];
		
	// create new view just for printing
	NSTextView *printView = [[NSTextView alloc]initWithFrame: 
							 NSMakeRect(0.0, 0.0, 8.5 * 72, 11.0 * 72)];
	NSPrintOperation *op;
		
	// copy the textview into the printview
	[printView insertText: [self allProblemText]];
	op = [NSPrintOperation printOperationWithView: printView printInfo: 
		  myPrintInfo];
	[op setShowsPrintPanel: YES];
	[[[NSDocument alloc] init] runModalPrintOperation: op delegate: nil didRunSelector: NULL 
										  contextInfo: NULL];
	
	[printView release];
}

// Outline view methods for displaying the list of problems encountered
// when trying to assign cars.
// Just present each known problem as its own item.
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	if (item == nil) {
		// root
		id obj = [[appDelegate_ problems] objectAtIndex: index];
		return obj;
	}
	return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
	return NO;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if (item == nil) {
		return [[appDelegate_ problems] count];
	}
	return 0;
}
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	return item;
}

// Returns the currently selected problems, or nil if none are selected.
- (NSString*) selectedProblemText {
	NSIndexSet *selectedRowIndexes = [problemsOutlineView_ selectedRowIndexes];
	
	if ([selectedRowIndexes count] == 0) {
		return nil;
	}
	
	NSMutableString *fullString = [NSMutableString string];
    NSUInteger currentIndex = [selectedRowIndexes firstIndex];
    while (currentIndex != NSNotFound) {	
		// TODO(bowdidge): Handle case where column gets reordered?
		NSString *currentProblem = [[appDelegate_ problems] objectAtIndex: currentIndex];
		[fullString appendFormat: @"%@\n", currentProblem];
        currentIndex = [selectedRowIndexes indexGreaterThanIndex:currentIndex];
    }
	return fullString;
}
@end

@implementation SwitchListAppDelegate
- (id) init {
	[super init];
	// Gather the names of the switchlist templates with native support.
	nameToSwitchListClassMap_ = [[NSMutableDictionary alloc] init];
	[nameToSwitchListClassMap_ setObject: [SwitchListView class] forKey: DEFAULT_SWITCHLIST_TEMPLATE];
	[nameToSwitchListClassMap_ setObject: [SwitchListReport class] forKey: @"Line Printer"];
	[nameToSwitchListClassMap_ setObject: [KaufmanSwitchListView class] forKey: @"San Francisco Belt Line B-7"];
	[nameToSwitchListClassMap_ setObject: [SouthernPacificSwitchListView class] forKey: @"Southern Pacific Narrow"];
	[nameToSwitchListClassMap_ setObject: [PICLReport class] forKey: @"PICL Report"];

	defaultFileManager_ = [[NSFileManager defaultManager] retain];
	problems_ = [[NSMutableArray alloc] init];
	outlineDelegate_ = nil;
	return self;
}

- (void) dealloc {
	[networkIconImage_ release];
	[defaultFileManager_ release];
	[problems_ release];
	[outlineDelegate_ release];
 	[super dealloc];
}

- (NSDictionary*) nameToSwitchListClassMap {
	return nameToSwitchListClassMap_;
}

// Either by user control or 
- (void) startWebServer {
	NSLog(@"Starting web server.");
	webController_ = [[WebServerDelegate alloc] init];
}

- (void) stopWebServer {
	NSLog(@"Shutting down web server.");
	[webController_ stopResponding];
	[webController_ release];
	webController_ = nil;
}

// Current behavior: Open an untitled document if launching app on its own.
- (BOOL) applicationShouldOpenUntitledFile: (NSApplication*) theApplication {
	return YES;
}

// Changes the web server address displayed to the named host and default port.
// Address is set up to appear and act like a web link.
- (void) setWebServerName: (NSString*) label withLink: (BOOL) hasLink {
	NSMutableAttributedString *webServerAttrString = [[[NSMutableAttributedString alloc] initWithString: label] autorelease];
    NSRange range = NSMakeRange(0, [webServerAttrString length]);

	[webServerAttrString beginEditing];
	[webServerAttrString addAttribute: NSFontAttributeName value: [NSFont systemFontOfSize:13.0] range: range];
	NSMutableParagraphStyle *mutParaStyle=[[[NSMutableParagraphStyle alloc] init] autorelease];
	[mutParaStyle setAlignment:NSCenterTextAlignment];
	[webServerAttrString addAttributes:[NSDictionary dictionaryWithObject:mutParaStyle forKey:NSParagraphStyleAttributeName] range: range];
	
	if (hasLink) {
		// make the text appear in blue
		[webServerAttrString addAttribute: NSLinkAttributeName value: label range: range];
		[webServerAttrString addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
		// make the text appear with an underline
		[webServerAttrString addAttribute: NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSSingleUnderlineStyle] range:range];
	} else {
		[webServerAttrString addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:range];
	}
	[webServerAttrString endEditing];

	[webAccessAddressMessage_ setAttributedStringValue: webServerAttrString];
}

// Changes the web server's state and UI to match status.
- (IBAction) setWebServerRunStatus: (bool) status {
	if (status) {
		[networkIconView_ setImage: networkIconImage_];
		[webAccessCheckBox_ setState: status];
		[connectAtMessage_ setTextColor: [NSColor blackColor]];

		NSString *currentHostname = CurrentHostname();
		if ([currentHostname isEqualToString: @"127.0.0.1"]) {
			currentHostname = @"localhost";
			[webAccessStatusMessage_ setStringValue: @"can't find network connection"];
		} else {
			[webAccessStatusMessage_ setStringValue: @""];
		}
		NSString *webServerName = [NSString stringWithFormat: @"http://%@:%d", currentHostname, DEFAULT_SWITCHLIST_PORT];
		[self setWebServerName: webServerName withLink: YES];
		[self startWebServer];
	} else {
		[networkIconView_ setImage: nil];
		[webAccessCheckBox_ setState: status];
		[webAccessStatusMessage_ setStringValue: @""];
		[connectAtMessage_ setTextColor: [NSColor grayColor]];
		[self setWebServerName: @"Not running" withLink: NO];
		[self stopWebServer];
	}
}

// Creates a new template name default if one isn't found in the user's defaults.
// Uses the enum-based default style to choose a value.
// Only needed to give SwitchList users before 0.7.4 a better experience.
- (void) convertSwitchListStylePreferenceIfNeeded {
	// Change default.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSNumber *defaultStyleNumber = [defaults objectForKey: GLOBAL_PREFS_SWITCH_LIST_DEFAULT_STYLE];
	NSString *defaultTemplate = [defaults objectForKey: GLOBAL_PREFS_SWITCH_LIST_DEFAULT_TEMPLATE];
	if (defaultStyleNumber != nil && defaultTemplate == nil) {
		// Upgrade to using template name.
		int preference = [defaultStyleNumber integerValue];
		NSString *templateName = nil;
		switch (preference) {
			case 1:
				// Classic handwritten switchlist.
				templateName = DEFAULT_SWITCHLIST_TEMPLATE; // Handwritten
				break;
			case 2:
				// Original computer-generated switchlist.
				templateName = @"LinePrinter";
				break;
			case 3:
			case 6:
				// B7 and pick up / drop off switchlist.
				templateName = @"San Francisco Belt Line B-7";
				break;
			case 4:
				templateName = @"Southern Pacific Narrow";
				break;
			case 5:
				templateName = @"PICL Report";
				break;
		}
		if (templateName) {
			[defaults setObject: templateName forKey: GLOBAL_PREFS_SWITCH_LIST_DEFAULT_TEMPLATE];
			// Don't erase old preference.
		}
	} else if (defaultTemplate == nil) {
		// Set some value in template just to make sure a value exists.
		[defaults setObject: DEFAULT_SWITCHLIST_TEMPLATE forKey: GLOBAL_PREFS_SWITCH_LIST_DEFAULT_TEMPLATE];
	}
}

// Load all fonts from the Application bundle.  Generate an error if the fonts in the array fontnames
// are not present.
- (BOOL)loadLocalFonts:(NSError **)err requiredFonts:(NSArray *)fontnames {
	NSString *resourcePath, *fontsFolder,*errorMessage;    
	NSURL *fontsURL;
	resourcePath = [[NSBundle mainBundle] resourcePath];
	if (!resourcePath) {
		errorMessage = @"Failed to load fonts! no resource path...";
		goto error;
	}

	fontsFolder = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"/fonts"];
	NSFileManager *fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:fontsFolder])	{
		errorMessage = @"Failed to load fonts! Font folder not found...";
		goto error;
	}
	
    fontsURL = [NSURL fileURLWithPath:fontsFolder];
	if (fontsURL) {
        FSRef fsRef;
        CFURLGetFSRef((CFURLRef)fontsURL, &fsRef);
        OSStatus status;
        // Prepare to switch to CoreText Font Manager - ATSFontActivate* is deprecated.
        status = ATSFontActivateFromFileReference(&fsRef, kATSFontContextLocal, kATSFontFormatUnspecified,
                                                  NULL, kATSOptionFlagsDefault, NULL);
        if (status != noErr) {
            errorMessage = @"Failed to activate fonts!";
            goto error;
        }
	}
	if (fontnames != nil) {
		NSFontManager *fontManager = [NSFontManager sharedFontManager];
		for (NSString *fontname in fontnames) {
			BOOL fontFound = [[fontManager availableFonts] containsObject:fontname]; 
			if (!fontFound) {
				errorMessage = [NSString stringWithFormat:@"Required font not found:%@",fontname];
				goto error;
			}
		}
	}
	return YES;

error:
	if (err != NULL) {
		NSString *localizedMessage = NSLocalizedString(errorMessage, @"");
		NSDictionary *userInfo = [NSDictionary dictionaryWithObject:localizedMessage forKey:NSLocalizedDescriptionKey];
		*err = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:0 userInfo:userInfo];
	}
	
	return NO;
	
}

// Puts the switchlist template names in the pop-up in sorted order,
// rescanning the template directories.
- (void) reloadSwitchlistTemplateNames {
	int pos=0;
	[switchListStyleButton_ removeAllItems];
	for (NSString *templateName in [self validTemplateNames]) {
		[switchListStyleButton_ insertItemWithTitle: templateName atIndex: pos++];
	}
	NSString *preferredSwitchlistStyle = [[NSUserDefaults standardUserDefaults] stringForKey: GLOBAL_PREFS_SWITCH_LIST_DEFAULT_TEMPLATE];
	[switchListStyleButton_ selectItemWithTitle: preferredSwitchlistStyle];
	[webController_ setTemplate: preferredSwitchlistStyle]; 
}	

- (void) awakeFromNib {
	[problems_ addObject: @"No problems."];
	MyOutlineDelegate *myOutlineDelegate = [[[MyOutlineDelegate alloc] initWithAppDelegate: self
																		   withOutlineView: problemsOutlineView_] autorelease];
	outlineDelegate_ = [myOutlineDelegate retain];
	[problemsOutlineView_ setDataSource: myOutlineDelegate];
	[problemsOutlineView_ setDelegate: myOutlineDelegate];
	[problemsOutlineView_ setAllowsMultipleSelection: YES];

	webServerVisible_ = [[NSUserDefaults standardUserDefaults] boolForKey: GLOBAL_PREFS_DISPLAY_WEB_SERVER];
	webServerEnabled_ = [[NSUserDefaults standardUserDefaults] boolForKey: GLOBAL_PREFS_ENABLE_WEB_SERVER];
	[webServerVisibleCheckBox_ setState: webServerVisible_];
	
	NSString *networkImageFile = [[NSBundle mainBundle] pathForResource: @"network_wireless" ofType: @"jpg"];
	networkIconImage_ = [[NSImage alloc] initWithContentsOfFile: networkImageFile];
	
	webController_ = nil;
	if (webServerVisible_) {
		[webServerStatusPanel_ orderFront: self];
		// Only run web server if panel visible.
		[self setWebServerRunStatus: webServerEnabled_];
	} else {
		[webServerStatusPanel_ orderOut: self];
		[self setWebServerRunStatus: NO];
	}
	
	[self convertSwitchListStylePreferenceIfNeeded];

	[self reloadSwitchlistTemplateNames];
	
	// Fill in the Examples menu.
	NSString *bundleRoot = [[NSBundle mainBundle] resourcePath];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *dirContents = [fm contentsOfDirectoryAtPath:bundleRoot error:nil];
	NSPredicate *switchlistFilter = [NSPredicate predicateWithFormat:@"self ENDSWITH '.swl'"];
	NSArray *switchlistExamples = [dirContents filteredArrayUsingPredicate:switchlistFilter];
	
	for (NSString *exampleFile in switchlistExamples) {
		// Remove four characters for .swl.
		NSString *exampleName = [exampleFile substringToIndex: [exampleFile length] - 4];
		[exampleMenu_ addItem:  [[[NSMenuItem alloc] initWithTitle: exampleName
															action: @selector(doOpenExample:)
													 keyEquivalent: @""] autorelease]];
	}
	NSError *err = nil;
	[self loadLocalFonts: &err requiredFonts: [NSArray array]];
}

- (BOOL)alertShowHelp:(NSAlert *)alert {
	// Open the help link in the alert.
	// TODO(bowdidge): Still doesn't appear to work.  Are spaces the problem?
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor: [alert helpAnchor] inBook: locBookName];
	return YES;
}

// Selector for the example menu items.  Opens the example named by the sending menu,
// and provides a helpful dialog box pointing the user at documentation.
- (IBAction) doOpenExample: (id) sender {
	NSMenuItem *chosenItem = (NSMenuItem*) sender;
	NSString *exampleName = [chosenItem title];
	NSString *exampleFile = [exampleName stringByAppendingPathExtension: @"swl"];
	NSString *examplePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent: exampleFile];
	NSURL *exampleURL = [NSURL fileURLWithPath: examplePath];
	NSError *error = nil;
	// Nonexistence of file isn't an error to NSDocumentController, so catch that issue explicitly.
	if ([[NSFileManager defaultManager] fileExistsAtPath: examplePath] == NO) {
		NSAlert *alert = [NSAlert alertWithMessageText: [NSString stringWithFormat: @"Example file %@ is missing.", exampleFile]
										 defaultButton: @"OK" alternateButton: nil otherButton: nil
							 informativeTextWithFormat: @"The example file can't be found in the application.  This version of SwitchList may be corrupted."];
		[alert runModal];
		return;
	}
	id result= [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL: exampleURL
																					  display: YES
																						error: &error];
	
	if (!result) {
		NSAlert *alert = [NSAlert alertWithMessageText: @"Cannot open example file."
										 defaultButton: @"OK" alternateButton: nil otherButton: nil
							 informativeTextWithFormat: @"%@", [error localizedDescription]];
		[alert runModal];
		return;
	}

	// Provide helpful hints.
	NSAlert *alert = [NSAlert alertWithMessageText: [NSString stringWithFormat: @"Example '%@' loaded.", exampleName]
									 defaultButton: @"OK" alternateButton: nil otherButton: nil
						 informativeTextWithFormat:
					  @"For more background on this example, check out the 'Example Layouts' section of the SwitchList help."];
	// Contact SwitchListAppDelegate for dispatching the help.
	[alert setDelegate: self];
	[alert setShowsHelp: YES];
	NSString *helpAnchor = [NSString stringWithFormat: @"Example%@", [exampleName stringByReplacingOccurrencesOfString:@" " withString:@""]];
	[alert setHelpAnchor: helpAnchor];
	[alert runModal];
	return;
}

// Copies a template file into the correct application specific directory for the application.
// Simplifies installing new templates, and avoids problems of cryptic paths that differ between
// app store and non-app store version.
- (IBAction) doImportTemplate: (id) sender {
	NSError *error;
	NSAlert *alert;
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseFiles: NO];
	[panel setCanChooseDirectories: YES];
	[panel setAllowsMultipleSelection: NO];
	[panel setMessage: @"Select directory containing the new switchlist style template files."];
	 
	int result = [panel runModal];
	if (result != NSOKButton) {
		// User cancelled.
		return;
	}

	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *selectedDirectory = [panel filename];
	NSString *templateName = [selectedDirectory lastPathComponent];
		
	NSString *oldCopyOfDirectory = nil;
	
	// Check to make sure the template doesn't already exist, and warn if so.
	NSString *userTemplateDirectory = [[fileManager applicationSupportDirectory] stringByAppendingPathComponent: templateName];

	if ([fileManager fileExistsAtPath: userTemplateDirectory]) {
		NSString *overwriteWarning = [NSString stringWithFormat: @"A template named '%@' has already been installed.  Overwrite?", templateName];
		alert = [NSAlert alertWithMessageText: overwriteWarning
								defaultButton: @"OK" alternateButton: @"Cancel" otherButton: nil
					informativeTextWithFormat: @""];
		int overwriteWarningResult = [alert runModal];
		if (overwriteWarningResult != NSOKButton) {
			// User doesn't want to overwrite. Cancel.
			return;
		}
		
		// User wants to overwrite.  Move old copy aside.
		NSString *existingDirectory = [[fileManager applicationSupportDirectory] stringByAppendingPathComponent: templateName];
		oldCopyOfDirectory = [[fileManager applicationSupportDirectory] stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.old", templateName]];
		int moveResult = [fileManager moveItemAtPath: existingDirectory toPath: oldCopyOfDirectory error: &error];
		if (moveResult == NO) {
			// Error during copying.  Warn, and return.
			alert = [NSAlert alertWithMessageText: @"Problems moving old copy of template out of the way."
											 defaultButton: @"OK" alternateButton: nil otherButton: nil
								 informativeTextWithFormat: [NSString stringWithFormat: @"%@.", [error localizedDescription]]];
			[alert runModal];
			return;
		}
	}

	// Copy the template directory into the application support directory.
	int copyResult = [fileManager copyItemAtPath: selectedDirectory 
										  toPath: [[fileManager applicationSupportDirectory] stringByAppendingPathComponent: templateName]
										   error: &error];
	if (copyResult == NO) {
		NSAlert *alert = [NSAlert alertWithMessageText: @"Problems copying template into place."
										 defaultButton: @"OK" alternateButton: nil otherButton: nil
							 informativeTextWithFormat: [NSString stringWithFormat: @"%@.", [error localizedDescription]]];
		[alert runModal];
		return;
	}
	
	// Delete old copy if it exists.
	if (oldCopyOfDirectory) {
		int moveResult = [fileManager removeItemAtPath: oldCopyOfDirectory error: &error];
		if (moveResult == NO) {
			NSAlert *alert = [NSAlert alertWithMessageText: @"New template is in place, but problems deleting old copy of template."
											 defaultButton: @"OK" alternateButton: nil otherButton: nil
								 informativeTextWithFormat: [NSString stringWithFormat: @"%@.", [error localizedDescription]]];
			[alert runModal];
			return;
		}
	}
	// Success. Return.
	[self reloadSwitchlistTemplateNames];
	return;
}

- (NSWindow*) reportWindow {
	return reportWindow_;
}

- (NSTextView*) reportTextView {
	return reportTextView_;
}

// Provides detailed error message - generally CoreData errors when writing a file.
- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error {
	NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
	NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
	if(detailedErrors != nil && [detailedErrors count] > 0) {
		for(NSError* detailedError in detailedErrors) {
			NSLog(@"  DetailedError: %@", [detailedError userInfo]);
		}
	}
	else {
		NSLog(@"  %@", [error userInfo]);
	}
	return error;
}


- (NSDocument<SwitchListDocumentInterface>*) currentDocument {
	NSWindow *win = [[NSApplication sharedApplication] mainWindow];
	NSWindowController *winc = [win windowController];
	if (winc == nil) {
		// Ok, it's probably a report.
		return [((Report*)[win delegate]) owningDocument];
	}
	SwitchListDocument *currentDocument = [winc document];
	return currentDocument;
}
- (IBAction) switchListFormatPreferenceChanged: (id) sender {
	int selection = [sender indexOfSelectedItem];
	NSString *preferredReportName = [sender itemTitleAtIndex: selection];
	[[NSUserDefaults standardUserDefaults] setObject: preferredReportName forKey: GLOBAL_PREFS_SWITCH_LIST_DEFAULT_TEMPLATE];
	[webController_ setTemplate: preferredReportName]; 
}

- (IBAction) webServerPreferenceChanged: (id) sender {
	bool newValue = [sender state];
	[[NSUserDefaults standardUserDefaults] setBool: newValue forKey: GLOBAL_PREFS_DISPLAY_WEB_SERVER];
	webServerVisible_ = newValue;
	if (newValue) {
		// Display server, and turn on if that's default.
		[webServerStatusPanel_ orderFront: self];
		webServerEnabled_ = [[NSUserDefaults standardUserDefaults] boolForKey: GLOBAL_PREFS_ENABLE_WEB_SERVER];
		[self setWebServerRunStatus: webServerEnabled_];
	} else {
		// Hide server, and turn off server regardless.
		[webServerStatusPanel_ orderOut: self];
		[self setWebServerRunStatus: NO];
	}
}

// Responds to click on the "web server enabled" checkbox in
// the web server panel.
- (IBAction) webServerRunStatusChanged: (id) sender {
	if (webServerEnabled_) {
		[self setWebServerRunStatus: NO];
		webServerEnabled_ = NO;
	} else {
		[self setWebServerRunStatus: YES];
		webServerEnabled_ = YES;
	}
	[[NSUserDefaults standardUserDefaults] setBool: webServerEnabled_ forKey: GLOBAL_PREFS_ENABLE_WEB_SERVER];
}

	
// Returns all the problem text.
- (NSArray*) problems {
	return problems_;
}

// Sets the list of problem strings to display in the Problems window.
- (void) setProblems: (NSArray*) problemStrings {
	[problems_ release];
	problems_ = [[NSMutableArray alloc] initWithArray:problemStrings];
	if ([problems_ count] == 0) {
		[problems_ addObject: @"No problems."];
		[problemsOutlineView_ reloadData];
	} else {
	    [problemsOutlineView_ reloadData];
		[problemsWindow_ makeKeyAndOrderFront: self];
	}
}

// Brings up the Help page for something in the prefences dialog. 
// Triggered by Help icon in preferences dialog.
// TODO(bowdidge): Rename to match generic use.
- (IBAction) switchListStyleHelpPressed: (id) sender {
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleHelpBookName"];
	[[NSHelpManager sharedHelpManager] openHelpAnchor: @"SwitchListPreferencesHelp" inBook: locBookName];
}

// Returns true if a directory named "name" exists in the specified directory,
// and if "name" contains a switchlist.html file suggesting it's a real template.
- (BOOL) isSwitchlistTemplate: (NSString*) name inDirectory: (NSString*) directory {
	BOOL isDirectory = NO;
	if (![defaultFileManager_ fileExistsAtPath: [directory stringByAppendingPathComponent: name]
								   isDirectory: &isDirectory] || isDirectory == NO) {
		return NO;
	}
	// Does a switchlist.html directory exist there?
	if ([defaultFileManager_ fileExistsAtPath: [[directory stringByAppendingPathComponent: name] 
												stringByAppendingPathComponent: @"switchlist.html"]]) {
		return YES;
	}
	return NO;
}

// Return the list of 
- (NSArray*) validTemplateNames {
	// Handwritten is always valid - uses defaults.
	NSMutableArray *result = [NSMutableArray arrayWithObject: DEFAULT_SWITCHLIST_TEMPLATE];

	NSError *error;
	// First find templates in application support directory.
	NSString *applicationSupportDirectory = [defaultFileManager_ applicationSupportDirectory];
	NSArray *filesInApplicationSupportDirectory = [defaultFileManager_ contentsOfDirectoryAtPath: applicationSupportDirectory
																						   error: &error];
	for (NSString *file in filesInApplicationSupportDirectory) {
		if ([self isSwitchlistTemplate: file inDirectory: applicationSupportDirectory]) {
			[result addObject: file];
		}
	}
	
	// Next, find templates in the bundle directory.  User templates with the same name win.
	NSString *resourcesDirectory = [[NSBundle mainBundle] resourcePath];
	NSArray *filesInResourcesDirectory = [defaultFileManager_ contentsOfDirectoryAtPath: resourcesDirectory
																				  error: &error];
	for (NSString *file in filesInResourcesDirectory) {
		if ([self isSwitchlistTemplate: file inDirectory: resourcesDirectory]) {
			if ([result containsObject: file] == NO) {
				[result addObject: file];
			}
		}
	}
	return [result sortedArrayUsingSelector: @selector(compare:)];
}
	
@end