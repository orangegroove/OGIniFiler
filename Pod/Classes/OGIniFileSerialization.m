//
//  OGIniFileSerialization.m
//  Pods
//
//  Created by Jesper on 23/10/14.
//
//

#import "OGIniFileSerialization.h"

NSString* const kOGIniFileSerializationErrorDomain = @"OGIniFileSerializationErrorDomain";

@implementation NSString (OGScanning)

- (NSString *)og_unescapedStringWithEscapeCharacterSet:(NSCharacterSet *)escapeCharacterSet
{
    NSScanner* scanner            = [NSScanner scannerWithString:self];
    NSMutableString* string       = [NSMutableString string];
    scanner.charactersToBeSkipped = nil;
    NSString* buffer;
    
    while (!scanner.isAtEnd)
    {
        [scanner scanUpToCharactersFromSet:escapeCharacterSet intoString:&buffer];
        [string appendString:buffer];
        
        if (!scanner.isAtEnd)
        {
            scanner.scanLocation++;
            
            if (!scanner.isAtEnd)
            {
                unichar nextchar = [self characterAtIndex:scanner.scanLocation];
                
                if ([escapeCharacterSet characterIsMember:nextchar])
                {
                    buffer = [buffer stringByAppendingFormat:@"%c", nextchar];
                    scanner.scanLocation++;
                }
            }
        }
    }
    
    return [string copy];
}

- (NSString *)og_stringWithCharacterSet:(NSCharacterSet *)characterSet escapedWithCharacter:(unichar)escapeCharacter
{
    NSScanner* scanner            = [NSScanner scannerWithString:self];
    NSMutableString* string       = [NSMutableString string];
    scanner.charactersToBeSkipped = nil;
    NSString* buffer;
    
    while (!scanner.isAtEnd)
    {
        buffer = nil;
        [scanner scanUpToCharactersFromSet:characterSet intoString:&buffer];
        
        if (scanner.isAtEnd)
        {
            if (buffer.length)
            {
                [string appendString:buffer];
            }
        }
        else
        {
            if (buffer.length)
            {
                [string appendFormat:@"%@%c%c", buffer, escapeCharacter, [self characterAtIndex:scanner.scanLocation]];
            }
            else
            {
                [string appendFormat:@"%c%c", escapeCharacter, [self characterAtIndex:scanner.scanLocation]];
            }
            
            scanner.scanLocation++;
        }
    }
    
    return [string copy];
}

- (NSUInteger)og_firstLocationOfUnescapedCharacterInSet:(NSCharacterSet *)characterSet escapeCharacterSet:(NSCharacterSet *)escapeCharacterSet
{
    NSRange range = [self rangeOfCharacterFromSet:characterSet];
    
    if (!range.location) return 0;
    
    while (range.location != NSNotFound)
    {
        if ([escapeCharacterSet characterIsMember:[self characterAtIndex:range.location-1]])
        {
            NSUInteger location = range.location + range.length;
            range               = [self rangeOfCharacterFromSet:characterSet options:0 range:NSMakeRange(location, self.length - location)];
        }
        else
        {
            return range.location;
        }
    }
    
    return NSNotFound;
}

@end

#pragma mark -

@implementation NSDictionary (OGIniFileSerialization)

+ (NSDictionary *)og_dictionaryWithContentsOfIniFile:(NSString *)path
{
    return [OGIniFileSerialization iniFromData:[NSData dataWithContentsOfFile:path] encoding:NSUTF8StringEncoding options:OGIniFileReadingOptionTrimValueWhitespace|OGIniFileReadingOptionTrimPropertyWhitespace|OGIniFileReadingOptionTrimSectionWhitespace|OGIniFileReadingOptionMergeDuplicateSections|OGIniFileReadingOptionMergeDuplicateProperties separatorCharacters:nil commentCharacters:nil escapeCharacters:nil error:nil];
}

- (NSData *)og_iniFileData
{
    return [OGIniFileSerialization dataFromIni:self encoding:NSUTF8StringEncoding options:OGIniFileWritingOptionBlankLineBetweenSections separatorCharacter:'=' commentCharacters:nil escapeCharacter:'\\' error:nil];
}

- (BOOL)og_isValidIni
{
    return [OGIniFileSerialization isValidIni:self error:nil];
}

@end

#pragma mark -

@implementation OGIniFileSerialization

#pragma mark - Public

+ (NSDictionary *)iniFromData:(NSData *)data encoding:(NSStringEncoding)encoding options:(OGIniFileReadingOption)options separatorCharacters:(NSCharacterSet *)separatorCharacters commentCharacters:(NSCharacterSet *)commentCharacters escapeCharacters:(NSCharacterSet *)escapeCharacters error:(NSError *__autoreleasing *)error
{
    NSString* string = [self _stringFromData:data encoding:encoding error:error];
    
    if (string)
    {
        if (!separatorCharacters) separatorCharacters = [NSCharacterSet characterSetWithCharactersInString:@"="];
        if (!commentCharacters)   commentCharacters   = [NSCharacterSet characterSetWithCharactersInString:@";"];
        if (!escapeCharacters)    escapeCharacters    = [NSCharacterSet characterSetWithCharactersInString:@"\\"];
        
        return [self _iniFromString:string options:options separatorCharacters:separatorCharacters commentCharacters:commentCharacters escapeCharacters:escapeCharacters error:error];
    }
    
    return nil;
}

+ (NSData *)dataFromIni:(NSDictionary *)ini encoding:(NSStringEncoding)encoding options:(OGIniFileWritingOption)options separatorCharacter:(unichar)separatorCharacter commentCharacters:(NSCharacterSet *)commentCharacters escapeCharacter:(unichar)escapeCharacter error:(NSError *__autoreleasing *)error
{
    if (!commentCharacters)
    {
        commentCharacters = [NSCharacterSet characterSetWithCharactersInString:@";"];
    }
    
    NSMutableString* string                  = [NSMutableString string];
    NSDictionary* unsectioned                = ini[NSNull.null];
    NSMutableCharacterSet* escapedCharacters = [commentCharacters mutableCopy];
    
    [escapedCharacters addCharactersInString:[NSString stringWithFormat:@"%c", separatorCharacter]];
    
    if (unsectioned)
    {
        [self _appendSectionTo:unsectioned options:options toString:string separatorCharacter:separatorCharacter escapedCharacters:escapedCharacters escapeCharacter:escapeCharacter];
        
        if (string.length && options & OGIniFileWritingOptionBlankLineBetweenSections)
        {
            [string appendString:@"\n"];
        }
    }
    
    [ini enumerateKeysAndObjectsUsingBlock:^(NSString* name, NSDictionary* section, BOOL *stop) {
        
        if ([name isKindOfClass:NSNull.class]) return;
        
        [string appendFormat:@"[%@]\n", [name og_stringWithCharacterSet:escapedCharacters escapedWithCharacter:escapeCharacter]];
        [self _appendSectionTo:section options:options toString:string separatorCharacter:separatorCharacter escapedCharacters:escapedCharacters escapeCharacter:escapeCharacter];
        
        if (options & OGIniFileWritingOptionBlankLineBetweenSections)
        {
            [string appendString:@"\n"];
        }
    }];
    
    return [string dataUsingEncoding:encoding];
}

+ (BOOL)isValidIni:(NSDictionary *)dictionary error:(NSError *__autoreleasing *)error
{
    NSParameterAssert(dictionary);
    
    __block BOOL valid = YES;
    
    for (id key in dictionary.allKeys)
    {
        if (![key isKindOfClass:NSString.class] || ![key isKindOfClass:NSNull.class])
        {
            valid = NO;
            
            if (error)
            {
                *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeIllegalSectionName userInfo:@{@"section": key}];
            }
            
            break;
        }
    }
    
    if (valid)
    {
        for (NSDictionary* section in dictionary.allValues)
        {
            if (![section isKindOfClass:NSDictionary.class])
            {
                valid = NO;
                
                if (error)
                {
                    *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeIllegalSectionContent userInfo:@{@"section": section}];
                }
                
                break;
            }
            
            [section enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                
                if (![key isKindOfClass:NSString.class])
                {
                    valid = NO;
                    *stop = YES;
                    
                    if (error)
                    {
                        *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeIllegalPropertyType userInfo:@{@"property": key}];
                    }
                }
                else if (![obj isKindOfClass:NSString.class])
                {
                    valid = NO;
                    *stop = YES;
                    
                    if (error)
                    {
                        *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeIllegalValueType userInfo:@{@"property": key, @"value": obj}];
                    }
                }
            }];
            
            if (!valid)
            {
                break;
            }
        }
    }
    
    return valid;
}

#pragma mark - Private

+ (NSString *)_stringFromData:(NSData *)data encoding:(NSStringEncoding)encoding error:(NSError **)error
{
    NSParameterAssert(data);
    
    if (!data.length && error)
    {
        *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeMissingInput userInfo:nil];
    }
    
    NSString* string = nil;
    
    if (data.length && encoding > 0)
    {
        string = [[NSString alloc] initWithData:data encoding:encoding];
    }
    
    if (data.length && !string)
    {
        BOOL lossy                        = NO;
        NSStringEncoding detectedEncoding = [NSString stringEncodingForData:data encodingOptions:nil convertedString:&string usedLossyConversion:&lossy];
        
        if (!detectedEncoding)
        {
            string = nil;
            
            if (error)
            {
                *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeUnknownStringEncoding userInfo:nil];
            }
        }
    }
    
    return string;
}

+ (NSDictionary *)_iniFromString:(NSString *)string options:(OGIniFileReadingOption)options separatorCharacters:(NSCharacterSet *)separatorCharacters commentCharacters:(NSCharacterSet *)commentCharacters escapeCharacters:(NSCharacterSet *)escapeCharacters error:(NSError **)error
{
    NSUInteger lineNumber                  = 0;
    BOOL abort                             = NO;
    NSScanner* lineScanner                 = [NSScanner scannerWithString:string];
    NSCharacterSet* newlineCharacterSet    = [NSCharacterSet newlineCharacterSet];
    NSCharacterSet* whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
    NSMutableDictionary* sections          = [NSMutableDictionary dictionary];
    NSMutableDictionary* thisSection       = [NSMutableDictionary dictionary];
    id<NSCopying> thisSectionName          = NSNull.null;
    NSString* line;
    
    while (!lineScanner.isAtEnd)
    {
        lineNumber++;
        BOOL didScan = [lineScanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&line];
        
        // blank lines
        if ((!didScan || !line.length) && (options & OGIniFileReadingOptionNoBlankLines))
        {
            abort = YES;
            
            if (error)
            {
                *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeIllegalBlankLine userInfo:@{@"lineNumber": @(lineNumber)}];
            }
            
            break;
        }
        
        // comments
        NSUInteger commentLocation = [line og_firstLocationOfUnescapedCharacterInSet:commentCharacters escapeCharacterSet:escapeCharacters];
        
        if (!commentLocation)
        {
            continue;
        }
        else if (commentLocation < line.length && !(options & OGIniFileReadingOptionOnlyBeginningOfLineComments))
        {
            line = [line substringToIndex:commentLocation];
        }
        
        // section
        if ([line hasPrefix:@"["] && [line hasSuffix:@"]"])
        {
            if (line.length > 2)
            {
                sections[thisSectionName] = (options & OGIniFileReadingOptionMutableReturnType)? thisSection : [thisSection copy];
                NSString* newSectionName  = [[line substringWithRange:NSMakeRange(1, line.length - 2)] og_unescapedStringWithEscapeCharacterSet:escapeCharacters];
                
                if (options & OGIniFileReadingOptionTrimSectionWhitespace)
                {
                    newSectionName = [(NSString *)newSectionName stringByTrimmingCharactersInSet:whitespaceCharacterSet];
                }
                
                if (sections[newSectionName])
                {
                    if (options & OGIniFileReadingOptionMergeDuplicateSections)
                    {
                        thisSection = [NSMutableDictionary dictionaryWithDictionary:sections[newSectionName]];
                    }
                    else if (options & OGIniFileReadingOptionIgnoreDuplicateSections)
                    {
                        thisSection = nil;
                    }
                    else if (options & OGIniFileReadingOptionOverwriteDuplicateSections)
                    {
                        thisSection = [NSMutableDictionary dictionary];
                    }
                }
                else
                {
                    thisSection = [NSMutableDictionary dictionary];
                }
                
                thisSectionName = newSectionName;
            }
            else
            {
                abort = YES;
                
                if (error)
                {
                    *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeMissingSectionName userInfo:@{@"lineNumber": @(lineNumber)}];
                }
                
                break;
            }
            
            continue;
        }
        
        // key/value pair
        if (thisSection)
        {
            NSString* key                = nil;
            NSString* value              = @"";
            NSUInteger separatorLocation = [line og_firstLocationOfUnescapedCharacterInSet:separatorCharacters escapeCharacterSet:escapeCharacters];
            
            if (separatorLocation < line.length)
            {
                key = [[line substringToIndex:separatorLocation] og_unescapedStringWithEscapeCharacterSet:escapeCharacters];
                
                if (line.length > separatorLocation + 1)
                {
                    value = [[line substringFromIndex:separatorLocation + 1] og_unescapedStringWithEscapeCharacterSet:escapeCharacters];
                }
            }
            else
            {
                abort = YES;
                
                if (error)
                {
                    *error = [NSError errorWithDomain:kOGIniFileSerializationErrorDomain code:OGIniFileSerializationErrorCodeMissingSeparator userInfo:@{@"lineNumber": @(lineNumber)}];
                }
            }
            
            if (options & OGIniFileReadingOptionTrimPropertyWhitespace)
            {
                key = [key stringByTrimmingCharactersInSet:whitespaceCharacterSet];
            }
            
            if (options & OGIniFileReadingOptionTrimValueWhitespace)
            {
                value = [value stringByTrimmingCharactersInSet:whitespaceCharacterSet];
            }
            
            if (thisSection[key])
            {
                if (options & OGIniFileReadingOptionMergeDuplicateProperties)
                {
                    id existingValue       = thisSection[key];
                    NSMutableArray* values = [NSMutableArray array];
                    
                    if ([existingValue isKindOfClass:NSArray.class])
                    {
                        [values addObjectsFromArray:existingValue];
                    }
                    else
                    {
                        [values addObject:existingValue];
                    }
                    
                    [values addObject:value];
                    
                    thisSection[key] = values;
                }
                else if (options & OGIniFileReadingOptionOverwriteDuplicateProperties)
                {
                    thisSection[key] = value;
                }
            }
            else
            {
                thisSection[key] = value;
            }
        }
    }
    
    if (abort)
    {
        return nil;
    }
    
    sections[thisSectionName] = (options & OGIniFileReadingOptionMutableReturnType)? thisSection : [thisSection copy];
    
    if (options & OGIniFileReadingOptionMutableReturnType)
    {
        return sections;
    }
    else
    {
        return [sections copy];
    }
}

+ (void)_appendSectionTo:(NSDictionary *)section options:(OGIniFileWritingOption)options toString:(NSMutableString *)string separatorCharacter:(unichar)separatorCharacter escapedCharacters:(NSCharacterSet *)escapedCharacters escapeCharacter:(unichar)escapeCharacter
{
    [section enumerateKeysAndObjectsUsingBlock:^(NSString* key, id obj, BOOL *stop) {
        
        if ([obj isKindOfClass:NSString.class])
        {
            [string appendFormat:@"%@%c%@\n", [key og_stringWithCharacterSet:escapedCharacters escapedWithCharacter:escapeCharacter], separatorCharacter, [obj og_stringWithCharacterSet:escapedCharacters escapedWithCharacter:escapeCharacter]];
        }
        else if ([obj isKindOfClass:NSArray.class])
        {
            for (NSString* item in obj)
            {
                [string appendFormat:@"%@%c%@\n", [key og_stringWithCharacterSet:escapedCharacters escapedWithCharacter:escapeCharacter], separatorCharacter, [item og_stringWithCharacterSet:escapedCharacters escapedWithCharacter:escapeCharacter]];
            }
        }
    }];
}

@end
