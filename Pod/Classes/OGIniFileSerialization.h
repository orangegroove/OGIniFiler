//
//  OGIniFileSerialization.h
//  Pods
//
//  Created by Jesper on 23/10/14.
//
//

/*
 Reading and writing INI files.
 */

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const kOGIniFileSerializationErrorDomain;

typedef NS_ENUM(uint64_t, OGIniFileSerializationErrorCode)
{
    /**
     The input data couldn't be encoded into a string.
     */
    OGIniFileSerializationErrorCodeUnknownStringEncoding = 1001,
    
    /**
     OGIniFileReadingOptionNoBlankLines was used and blank lines were found.
     */
    OGIniFileSerializationErrorCodeIllegalBlankLine      = 1002,
    
    /**
     No input data.
     */
    OGIniFileSerializationErrorCodeMissingInput          = 1003,
    
    /**
     Line contains a section, but no section name.
     */
    OGIniFileSerializationErrorCodeMissingSectionName    = 1004,
    
    /**
     Line does not contain a separator character.
     */
    OGIniFileSerializationErrorCodeMissingSeparator      = 1005,
    
    /**
     Section name is not a string.
     */
    OGIniFileSerializationErrorCodeIllegalSectionName    = 1006,
    
    /**
     Section content is not a dictionary.
     */
    OGIniFileSerializationErrorCodeIllegalSectionContent = 1007,
    
    /**
     Property is not a string.
     */
    OGIniFileSerializationErrorCodeIllegalPropertyType   = 1008,
    
    /**
     Value is not a string.
     */
    OGIniFileSerializationErrorCodeIllegalValueType      = 1009
};

typedef NS_OPTIONS(uint64_t, OGIniFileReadingOption)
{
    /**
     Interpret comment characters as comments only as the first character of a line.
     */
    OGIniFileReadingOptionOnlyBeginningOfLineComments  = 1 << 0,
    
    /**
     Do not allow blank lines.
     */
    OGIniFileReadingOptionNoBlankLines                 = 1 << 1,
    
    /**
     Trim values.
     */
    OGIniFileReadingOptionTrimValueWhitespace          = 1 << 2,
    
    /**
     Trim properties.
     */
    OGIniFileReadingOptionTrimPropertyWhitespace       = 1 << 3,
    
    /**
     Trim section names.
     */
    OGIniFileReadingOptionTrimSectionWhitespace        = 1 << 4,
    
    /**
     Outputs a mutable container and mutable sections.
     */
    OGIniFileReadingOptionMutableReturnType            = 1 << 5,
    
    /**
     Merge properties from sections with duplicate names.
     */
    OGIniFileReadingOptionMergeDuplicateSections       = 1 << 11,
    
    /**
     Ignore properties from sections with duplicate names.
     */
    OGIniFileReadingOptionIgnoreDuplicateSections      = 1 << 12,
    
    /**
     Overwrite properties from sections with duplicate names.
     */
    OGIniFileReadingOptionOverwriteDuplicateSections   = 1 << 13,
    
    /**
     Merge values from properties in the same section into arrays.
     */
    OGIniFileReadingOptionMergeDuplicateProperties     = 1 << 21,
    
    /**
     Ignore values from properties in the same section with duplicate names.
     */
    OGIniFileReadingOptionIgnoreDuplicateProperties    = 1 << 22,
    
    /**
     Overwrite values from properties in the same section with duplicate names.
     */
    OGIniFileReadingOptionOverwriteDuplicateProperties = 1 << 23
};

typedef NS_OPTIONS(uint64_t, OGIniFileWritingOption)
{
    /**
     Adds a blank line above a section header in the output.
     */
    OGIniFileWritingOptionBlankLineBetweenSections     = 1 << 0
};

@interface NSDictionary (OGIniFileSerialization)

/**
 Convenience method for +iniFromData:encoding:options:separatorCharacters:commentCharacters:escapeCharacters:error in OGIniFileSerialization.
 @param path Path of the file to open.
 @return The parsed dictionary.
 */
+ (nullable NSDictionary *)og_dictionaryWithContentsOfIniFile:(NSString *)path;

/**
 Convenience method for +dataFromIni:options:encoding:error: in OGIniFileSerialization.
 @return The parsed data.
 */
- (nullable NSData *)og_iniFileData;

/**
 Convenience method for +isValidIni:error: in OGIniFileSerialization.
 @return Whether the dictionary is valid as an ini file.
 */
- (BOOL)og_isValidIni;

@end

@interface OGIniFileSerialization : NSObject

/**
 Parses an ini file.
 @param data Input data.
 @param encoding The string encoding.
 @param options Reading options.
 @param separatorCharacters Property and value delimiter. Defaults to equal sign if nil.
 @param commentCharacters Characters to interpret as comments. Defaults to semicolon if nil. If no comments are allowed, pass an empty characterSet.
 @param escapeCharacters Characters to interpret as escape characters. Defaults to backslash if nil. If no escape characters are used, pass an empty characterSet.
 @param error If unsuccessful, examine this to find out why.
 @return The parsed ini file. Nil if unsuccessful.
 */
+ (nullable NSDictionary *)iniFromData:(NSData *)data encoding:(NSStringEncoding)encoding options:(OGIniFileReadingOption)options separatorCharacters:(nullable NSCharacterSet *)separatorCharacters commentCharacters:(nullable NSCharacterSet *)commentCharacters escapeCharacters:(nullable NSCharacterSet *)escapeCharacters error:(NSError * __nullable *)error;

/**
 Outputs an ini file as NSData.
 @param ini The inifile dictionary.
 @param encoding The string encoding.
 @param options Writing options.
 @param separatorCharacters Property and value delimiter. Defaults to equal sign if nil.
 @param commentCharacters Characters to interpret as comments. Defaults to semicolon if nil. If no comments are allowed, pass an empty characterSet.
 @param escapeCharacters Characters to interpret as escape characters. Defaults to backslash if nil. If no escape characters are used, pass an empty characterSet.
 @param error If unsuccessful, examine this to find out why.
 @return The data. Nil if unsuccessful.
 */
+ (nullable NSData *)dataFromIni:(NSDictionary *)ini encoding:(NSStringEncoding)encoding options:(OGIniFileWritingOption)options separatorCharacter:(unichar)separatorCharacter commentCharacters:(nullable NSCharacterSet *)commentCharacters escapeCharacter:(unichar)escapeCharacter error:(NSError * __nullable *)error;

/**
 Validation method.
 @param The dictionary to validate.
 @param error If invalid, examine this to find out why.
 @return Whether the input is valid as an ini file.
 */
+ (BOOL)isValidIni:(NSDictionary *)dictionary error:(NSError * __nullable *)error;

@end

NS_ASSUME_NONNULL_END
