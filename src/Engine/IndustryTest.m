//
//  IndustryTest.m
//  SwitchList
//
//  Created by Robert Bowdidge on 10/28/10.
//
// Copyright (c)2010 Robert Bowdidge,
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

#import "IndustryTest.h"

#import "EntireLayout.h"
#import "Industry.h"
#import "Place.h"


@implementation IndustryTest
// Checks that the workbench industry object exists once we request it.
- (void) testWorkbenchIndustry {
	// Make sure we allocate one and only one workbench industry.
	id entireLayout = [[EntireLayout alloc] initWithMOC: context_];
	
	XCTAssertNotNil([entireLayout workbenchIndustry], @"Workbench industry not defined.");
	
	Industry *workbenchIndustry = [entireLayout workbenchIndustry];

	XCTAssertFalse([workbenchIndustry isYard], @"Workbench industry should not be yard.");
	XCTAssertEqualObjects([workbenchIndustry name], @"Workbench", @"Name of workbench is not workbench.");
	XCTAssertFalse([workbenchIndustry canReceiveCargo], @"Workbench should not receive cargo.");
	// Workbench doesn't count as an industry - only stuff receiving cargo.
    XCTAssertEqualInt(0, [[entireLayout allIndustries] count], @"Wrong industry count");

	// Workbench industry must be requested to populate both industry and place.
	Place *workbench = [entireLayout workbench];
	XCTAssertEqualInt(1, [[workbench industries] count], @"Workbench does not have an industry.");
	XCTAssertEqualObjects([[workbench industries] anyObject],
						 [entireLayout workbenchIndustry], @"Workbench does not have workbench industry.");
}

// TODO(bowdidge): Move to freight car test eventually.
- (void) testIndustryDivision {
	[self makeThreeStationLayout];
	Industry *industry = [self industryAtStation: @"A"];
	XCTAssertNotNil(industry, @"Search for A-industry");
	
	XCTAssertNil([industry division], @"Check foreign car has foreign division");
	
	[industry setDivision: @"BN"];
	XCTAssertEqualObjects([industry division], @"BN", @"Check setting home division is permanent.");
	[industry setDivision: @"Here"];
	XCTAssertEqualObjects([industry division], @"Here", @"Check setting home division to Here works.");
	
	
	[industry setDivision: nil];
	XCTAssertEqualObjects(nil, [industry division], @"Check setting home division to empty string works.");
	
	[industry setDivision: @" "];
	XCTAssertEqualObjects(@" ",[industry division], @"Check setting home division to spaces works.");
}

- (void) testIndustrySidingLength {
	[self makeThreeStationLayout];
	Industry *industry = [self industryAtStation: @"A"];
	[industry setSidingLength: [NSNumber numberWithInt: 40]];
	XCTAssertEqualInt(40, [[industry sidingLength] intValue], @"Siding length not saved correctly.");

	Industry *industryB = [self industryAtStation: @"B"];
	XCTAssertEqualInt(0, [[industryB sidingLength] intValue], @"Unset siding length should be nil, not %@.", [industryB sidingLength]);
}

- (void) testYardSidingLength {
	[self makeThreeStationLayout];
	[self makeYardAtStation: @"A"];
	Yard *yard = [self yardAtStation: @"A"];
	XCTAssertEqualInt(0, [[yard sidingLength] intValue], @"Yard siding length should be nil, not %@.", [yard sidingLength]);
}

- (void) testIndustryDoors {
	[self makeThreeStationLayout];
	Industry *i = [self industryAtStation: @"A"];
	[i setHasDoors: YES];
	[i setNumberOfDoors: [NSNumber numberWithInt: 3]];
	
	XCTAssertEqualInt(3, [[i doorList] count], @"");
	XCTAssertEqual([NSNumber numberWithInt: 1], [[i doorList] objectAtIndex: 0], @"");
	XCTAssertEqual([NSNumber numberWithInt: 3], [[i doorList] objectAtIndex: 2], @"");
}	

@end
