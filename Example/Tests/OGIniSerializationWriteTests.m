//
//  OGIniSerializationWriteTests.m
//  OGIniFiler
//
//  Created by Jesper on 27/10/14.
//  Copyright (c) 2014 Jesper. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <OGIniFiler/OGIniFileSerialization.h>

@interface OGIniSerializationWriteTests : XCTestCase

@end

@implementation OGIniSerializationWriteTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testWrite
{
    NSError* error    = nil;
    NSString* path    = [NSBundle.mainBundle pathForResource:@"valid" ofType:@"ini"];
    NSData* data      = [NSData dataWithContentsOfFile:path];
    NSDictionary* ini = [OGIniFileSerialization iniFromData:data encoding:NSUTF8StringEncoding options:OGIniFileReadingOptionMergeDuplicateProperties|OGIniFileReadingOptionMergeDuplicateSections|OGIniFileReadingOptionTrimSectionWhitespace|OGIniFileReadingOptionTrimPropertyWhitespace|OGIniFileReadingOptionTrimValueWhitespace separatorCharacters:nil commentCharacters:nil escapeCharacters:nil error:&error];
    
    NSData* output = [OGIniFileSerialization dataFromIni:ini encoding:NSUTF8StringEncoding options:OGIniFileWritingOptionBlankLineBetweenSections separatorCharacter:'=' commentCharacters:nil escapeCharacter:'\\' error:&error];
    
    XCTAssert(output.length);
}

@end
