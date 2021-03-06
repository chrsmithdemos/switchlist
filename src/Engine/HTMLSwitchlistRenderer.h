//
//
//  HTMLSwitchlistRenderer.h
//  SwitchList
//
//  Created by bowdidge on 8/30/2011
//
// Copyright (c)2011 Robert Bowdidge,
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
//

// HTMLSwitchlistRenderer: Hide the details of where to find switchlist
// template files, and how to turn the templates into HTML.

#import <Foundation/Foundation.h>

@class MGTemplateEngine;
@class ScheduledTrain;
@class EntireLayout;

@interface HTMLSwitchlistRenderer : NSObject {
	// Shared copy of mainBundle object to minimize calls to [NSBundle mainBundle].
	NSBundle *mainBundle_;
	// Template renderer object.
	MGTemplateEngine *engine_;
	// Directory containing user's preferred set of switchlist templates.
	NSString* templateDirectory_;
    // Array of pairs of [option name,
    NSArray* optionalSettings_;
}

// Create a new HTMLSwitchlistRenderer.
//   bundle: pointer to app's main bundle, used for finding default switchlist files.
- (id) initWithBundle: (NSBundle*) bundle;

// Directory containing current switchlist template.  Needed for finding CSS files
// after rendering.
- (NSString*) templateDirectory;

// Sets the current template used for switchlists to the named template.
// The user's application support folder (~/Library/Application Support/SwitchList) will be
// searched first, followed by the Resources directory of the application bundle.
// If no directory with the template's name is found in either directory or if the
// template name is nil, then the default switchlist will be used.
- (void) setTemplate: (NSString*) templateName;	
- (NSString *) filePathForSwitchlistHTML;
- (NSString *) filePathForSwitchlistIPhoneHTML;

// Returns the list of optional variable present in the template.  These are used for custom appearances that
// should default to a sane value - for example, printing "Mid-Continent Terminal Railway" unless OPTIONS_NAME appears.
// The regex matches with:
// var anything = {{OPTIONAL_NAME | default: Mid-Continent Terminal Railway}};
// Returns a mutable array of pairs of [option name, option default value].
- (NSArray*) optionalSettingsForTemplateHtml: (NSString*) template;

// Returns the list of optional settings in the template HTML provided as a string.
// Returns a mutable array of pairs of [option_name (with OPTIONAL_ strripped), default value].
- (NSArray*) optionalSettingsForTemplateWithContents: (NSString*) templateContents;

// Set the optional settings as a list of pairs of (setting, custom value.
- (void) setOptionalSettings: (NSArray*) optionalSettings;

// Returns the path to the named file, either in the current template directory
// or in the main bundle.  Error if in neither.
- (NSString*) filePathForTemplateFile: (NSString*) filename;	

// Returns the path to the template with the given name, as found in one of the switchlist template
// directories.  If none can be found, it uses the copy in the main bundle.
- (NSString*) filePathForTemplateHtml: (NSString*) template;

// Generates the HTML for the requested train's switchlist.  isIphone determines whether the iPhone-specific
// template should be used.  isInteractive determines whether interactive variable is set in template, enabling
// any buttons or controls in page.  isInteractive should be 0 for printing.
- (NSString *) renderSwitchlistForTrain: (ScheduledTrain*) train layout: (EntireLayout*)layout iPhone: (BOOL) isIPhone
                            interactive: (BOOL) isInteractive;
- (NSString*) renderCarlistForLayout: (EntireLayout*) layout;
- (NSString*) renderIndustryListForLayout: (EntireLayout*) layout;
- (NSString*) renderYardReportForLayout: (EntireLayout*) layout;
- (NSString*) renderCargoReportForLayout: (EntireLayout*) layout;
- (NSString*) renderReservedCarReportForLayout: (EntireLayout*) layout;
- (NSString*) renderLayoutPageForLayout: (EntireLayout*) layout;
- (NSString*) renderLayoutsPageWithLayouts: (NSArray*) allLayouts;
// Renders a generic report (in reportName.html) using the provided template dictionary.
- (NSString*) renderReport: (NSString*) reportName withDict: (NSDictionary*) templateDict;
@end
