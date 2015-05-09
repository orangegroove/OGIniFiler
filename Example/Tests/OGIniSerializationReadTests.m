//
//  OGIniSerializationTests.m
//  OGIniFiler
//
//  Created by Jesper on 25/10/14.
//  Copyright (c) 2014 Jesper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OGIniFiler/OGIniFileSerialization.h>

@interface OGIniSerializationTests : XCTestCase

@end
@implementation OGIniSerializationTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testRead
{
    NSError* error    = nil;
    NSString* path    = [NSBundle.mainBundle pathForResource:@"valid" ofType:@"ini"];
    NSData* data      = [NSData dataWithContentsOfFile:path];
    NSDictionary* ini = [OGIniFileSerialization iniFromData:data encoding:NSUTF8StringEncoding options:OGIniFileReadingOptionMergeDuplicateProperties|OGIniFileReadingOptionMergeDuplicateSections|OGIniFileReadingOptionTrimSectionWhitespace|OGIniFileReadingOptionTrimPropertyWhitespace|OGIniFileReadingOptionTrimValueWhitespace separatorCharacters:nil commentCharacters:nil escapeCharacters:nil error:&error];
    
    XCTAssert(ini.count, @"Error: %@", error);
}

@end
