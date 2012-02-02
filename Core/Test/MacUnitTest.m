//
//  MacUnitTest.m
//  MacUnitTest
//
//  Created by Oliver Drobnik on 22.01.12.
//  Copyright (c) 2012 Drobnik KG. All rights reserved.
//

#import "MacUnitTest.h"
#import "DTHTMLAttributedStringBuilder.h"

#import </usr/include/objc/objc-class.h>


@implementation MacUnitTest


NSString *testCaseNameFromURL(NSURL *URL, BOOL withSpaces);

NSString *testCaseNameFromURL(NSURL *URL, BOOL withSpaces)
{
	NSString *fileName = [[URL path] lastPathComponent];
	NSString *name = [fileName stringByDeletingPathExtension];
	if (withSpaces)
	{
		name = [name stringByReplacingOccurrencesOfString:@"_" withString:@" "];
	}
	
	return name;
}

+ (void)initialize
{
	if (self == [MacUnitTest class])
	{
		// get list of test case files
		NSBundle *unitTestBundle = [NSBundle bundleForClass:self];
		NSString *testcasePath = [unitTestBundle resourcePath];
		
		// make one temp folder for all cases
		NSString *timeStamp = [NSString stringWithFormat:@"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0];
		NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:timeStamp];
		
		NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtPath:testcasePath];
		
		NSString *testFile = nil;
		while ((testFile = [enumerator nextObject]) != nil) {
			if (![testFile hasSuffix:@".html"])
			{
				// ignore other files, e.g. custom parameters in plist
				continue;
			}
			
			if ([testFile hasSuffix:@"WarAndPeace.html"])
			{
				// too large, skip that
				continue;
			}
			
			NSString *path = [testcasePath stringByAppendingPathComponent:testFile];
			NSURL *URL = [NSURL fileURLWithPath:path];
			
			NSString *caseName = testCaseNameFromURL(URL, NO);
			NSString *selectorName = [NSString stringWithFormat:@"test_%@", caseName];
			
			void(^impBlock)(MacUnitTest *) = ^(MacUnitTest *test) {
				[test internalTestCaseWithURL:URL withTempPath:tempPath];
			};
			
			IMP myIMP = imp_implementationWithBlock((__bridge void *)impBlock);
			
			SEL selector = NSSelectorFromString(selectorName);
			
			class_addMethod([self class], selector, myIMP, "v@:");
		}
	}
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)internalTestCaseWithURL:(NSURL *)URL withTempPath:(NSString *)tempPath
{
	// use utf16 internally, otherwise the MAC version chokes on the ArabicTest
	NSStringEncoding encoding = 0;
	NSString *testString = [NSString stringWithContentsOfURL:URL usedEncoding:&encoding error:NULL];
	NSData *testData = [testString dataUsingEncoding:NSUTF16StringEncoding];
	
	// built in HTML parsing
	NSError *error = nil;
	NSDictionary *docAttributes;
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:NSHTMLTextDocumentType, NSDocumentTypeDocumentOption, @"utf16", NSTextEncodingNameDocumentOption, nil];
	NSAttributedString *macAttributedString = [[NSAttributedString alloc] initWithData:testData options:options documentAttributes:&docAttributes error:&error];

	NSString *macString = [macAttributedString string];

	// our own builder
	DTHTMLAttributedStringBuilder *doc = [[DTHTMLAttributedStringBuilder alloc] initWithHTML:testData options:nil documentAttributes:NULL];

	[doc buildString];
	
	NSAttributedString *iosAttributedString = [doc generatedAttributedString];
	NSString *iosString = [iosAttributedString string];
	
	/*

	// Create characters view
	NSMutableString *dumpOutput = [[NSMutableString alloc] init];
	NSData *dump = [macString dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%x %c\n", b, b];
	}
	
	dump = [iosString dataUsingEncoding:NSUTF8StringEncoding];
	for (NSInteger i = 0; i < [dump length]; i++)
	{
		char *bytes = (char *)[dump bytes];
		char b = bytes[i];
		
		[dumpOutput appendFormat:@"%x %c\n", b, b];
	}
	
	NSLog(@"%@\n\n", dumpOutput);

	
	NSDictionary *attributes = nil;
	NSRange effectiveRange = NSMakeRange(0, 0);
	
		while ((attributes = [macAttributedString attributesAtIndex:effectiveRange.location effectiveRange:&effectiveRange]))
		{
			[dumpOutput appendFormat:@"Range: (%d, %d), %@\n\n", effectiveRange.location, effectiveRange.length, attributes];
			effectiveRange.location += effectiveRange.length;
			
			if (effectiveRange.location >= [macString length])
			{
				break;
			}
		}
	*/
	
	//NSLog(@"%@", dumpOutput);

	STAssertEquals([macString length], [iosString length], @"String output has different length");
	
	STAssertEqualObjects(macString, iosString, @"String output differs");
}

@end