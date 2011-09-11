//
//  Cargo.h
//  SwitchList
//
//  Created by Robert Bowdidge on 6/9/06.
//
// Copyright (c)2006 Robert Bowdidge,
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

#import <CoreData/CoreData.h>

@class CarType;
@class InduYard;

@interface Cargo :  NSManagedObject  
{
}

// Does the car occur with some random chance, or shopuld exactly the
// requested number of cars appear every operating session?
// TODO(bowdidge): Rename to "fixedRate" when we next redo the schema.
@property (nonatomic, retain) NSNumber *priority;
@property(nonatomic, retain) CarType* carTypeRel;
@property (nonatomic, retain) NSString* cargoDescription;
@property (nonatomic, retain) InduYard* source, *destination;


- (NSNumber *)carsPerWeek;
- (void)setCarsPerWeek:(NSNumber *)value;

// Only for consistency in template language.
- (NSString*) name;

- (BOOL) isSourceOffline;
- (BOOL) isDestinationOffline;

@end
