//
//  ATUtilitiesTests.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/15/11.
//  Copyright 2011 Apptentive, Inc.. All rights reserved.
//

#import "ATUtilitiesTests.h"


@implementation ATUtilitiesTests
- (void)testEvenRect {
	CGRect testRect1 = CGRectMake(0.0, 0.0, 17.0, 21.0);
	CGRect result1 = ATCGRectOfEvenSize(testRect1);
	STAssertEquals(result1.size.width, (CGFloat)18.0, @"");
	STAssertEquals(result1.size.height, (CGFloat)22.0, @"");
	
	CGRect testRect2 = CGRectMake(0.0, 0.0, 18.0, 22.0);
	CGRect result2 = ATCGRectOfEvenSize(testRect2);
	STAssertEquals(result2.size.width, (CGFloat)18.0, @"");
	STAssertEquals(result2.size.height, (CGFloat)22.0, @"");
}

- (void)testDateFormatting {
	// This test will only pass when the time zone is PST. *sigh*
	NSDate *date = [NSDate dateWithTimeIntervalSince1970:1322609978.669914];
	STAssertEqualObjects(@"2011-11-29 15:39:38.669914 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.669];
	STAssertEqualObjects(@"2011-11-29 15:39:38.669 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.0];
	STAssertEqualObjects(@"2011-11-29 15:39:38 -0800", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:-8*60*60]], @"date doesn't match");
	
	date = [NSDate dateWithTimeIntervalSince1970:1322609978.0];
	STAssertEqualObjects(@"2011-11-29 23:39:38 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]], @"date doesn't match");
	
	NSString *string = @"2012-09-07T23:01:07+00:00";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07Z";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07.111+00:00";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 23:01:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
	
	string = @"2012-09-07T23:01:07.111+02:33";
	date = [ATUtilities dateFromISO8601String:string];
	STAssertNotNil(date, @"date shouldn't be nil");
	STAssertEqualObjects(@"2012-09-07 20:28:07 +0000", [ATUtilities stringRepresentationOfDate:date timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]], @"date doesn't match");
}

- (void)testVersionComparisons {
	STAssertTrue([ATUtilities versionString:@"6.0" isEqualToVersionString:@"6.0"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"0.0" isEqualToVersionString:@"0.0"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"6.0.1" isEqualToVersionString:@"6.0.1"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"0.0.1" isEqualToVersionString:@"0.0.1"], @"Should be same");
	STAssertTrue([ATUtilities versionString:@"10.10.1" isEqualToVersionString:@"10.10.1"], @"Should be same");
	
	STAssertTrue([ATUtilities versionString:@"10.10.1" isGreaterThanVersionString:@"10.10.0"], @"Should be greater");
	STAssertTrue([ATUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.0.1"], @"Should be greater");
	STAssertTrue([ATUtilities versionString:@"6.0" isGreaterThanVersionString:@"5.1"], @"Should be greater");
	
	STAssertTrue([ATUtilities versionString:@"5.0" isLessThanVersionString:@"5.1"], @"Should be less");
	STAssertTrue([ATUtilities versionString:@"5.0" isLessThanVersionString:@"6.0.1"], @"Should be less");
}

- (void)testCacheControlParsing {
	STAssertEquals(0., [ATUtilities maxAgeFromCacheControlHeader:nil], @"Should be same");
	STAssertEquals(0., [ATUtilities maxAgeFromCacheControlHeader:@""], @"Should be same");
	STAssertEquals(86400., [ATUtilities maxAgeFromCacheControlHeader:@"Cache-Control: max-age=86400, private"], @"Should be same");
	STAssertEquals(86400., [ATUtilities maxAgeFromCacheControlHeader:@"max-age=86400, private"], @"Should be same");
	STAssertEquals(47.47, [ATUtilities maxAgeFromCacheControlHeader:@"max-age=47.47, private"], @"Should be same");
	STAssertEquals(0., [ATUtilities maxAgeFromCacheControlHeader:@"max-age=0, private"], @"Should be same");
}

- (void)testThumbnailSize {
	CGSize imageSize, maxSize, result;
	
	imageSize = CGSizeMake(10, 10);
	maxSize = CGSizeMake(4, 3);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	STAssertTrue(CGSizeEqualToSize(result, CGSizeMake(3, 3)), @"Should be 3x3 thumbnail.");
	
	imageSize = CGSizeMake(10, 10);
	maxSize = CGSizeMake(11, 20);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	STAssertTrue(CGSizeEqualToSize(result, CGSizeMake(10, 10)), @"Should be 10x10 thumbnail.");
	
	imageSize = CGSizeMake(6, 8);
	maxSize = CGSizeMake(4, 4);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	STAssertTrue(CGSizeEqualToSize(result, CGSizeMake(3, 4)), @"Should be 3x4 thumbnail.");
	
	imageSize = CGSizeMake(8, 6);
	maxSize = CGSizeMake(6, 6);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	STAssertTrue(CGSizeEqualToSize(result, CGSizeMake(6, 4)), @"Should be 6x4 thumbnail.");
	
	imageSize = CGSizeMake(800, 600);
	maxSize = CGSizeMake(600, 600);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	STAssertTrue(CGSizeEqualToSize(result, CGSizeMake(600, 450)), @"Should be 600x450 thumbnail.");
	
	imageSize = CGSizeMake(0, 0);
	maxSize = CGSizeMake(6, 6);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	STAssertTrue(CGSizeEqualToSize(result, CGSizeMake(0, 0)), @"Should be 0x0 thumbnail.");
	
	imageSize = CGSizeMake(6, 6);
	maxSize = CGSizeMake(0, 0);
	result = ATThumbnailSizeOfMaxSize(imageSize, maxSize);
	STAssertTrue(CGSizeEqualToSize(result, CGSizeMake(0, 0)), @"Should be 0x0 thumbnail.");
}

- (void)testThumbnailCrop {
	CGSize imageSize, thumbSize;
	CGRect result, expected;
	
	imageSize = CGSizeMake(1200, 1600);
	thumbSize = CGSizeMake(100, 100);
	result = ATThumbnailCropRectForThumbnailSize(imageSize, thumbSize);
	expected = CGRectMake(0, 200, 1200, 1200);
	STAssertTrue(CGRectEqualToRect(result, expected), @"Expected %@, got %@", NSStringFromCGRect(expected), NSStringFromCGRect(result));
	
	imageSize = CGSizeMake(1600, 1200);
	thumbSize = CGSizeMake(100, 100);
	result = ATThumbnailCropRectForThumbnailSize(imageSize, thumbSize);
	expected = CGRectMake(200, 0, 1200, 1200);
	STAssertTrue(CGRectEqualToRect(result, expected), @"Expected %@, got %@", NSStringFromCGRect(expected), NSStringFromCGRect(result));
	
	imageSize = CGSizeMake(1600, 1200);
	thumbSize = CGSizeMake(800, 600);
	result = ATThumbnailCropRectForThumbnailSize(imageSize, thumbSize);
	expected = CGRectMake(0, 0, 1600, 1200);
	STAssertTrue(CGRectEqualToRect(result, expected), @"Expected %@, got %@", NSStringFromCGRect(expected), NSStringFromCGRect(result));
}

- (void)testDictionaryEquality {
	NSDictionary *a = nil;
	NSDictionary *b = nil;
	
	STAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
	
	a = @{};
	STAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = nil;
	b = @{};
	STAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = @{};
	b = @{};
	STAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
	
	a = @{@"foo":@"bar"};
	b = @{@"foo":@"bar"};
	STAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
	
	a = @{@"foo":@[@1, @2, @3]};
	b = @{@"foo":@[@1, @2, @4]};
	STAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = @{@"foo":@[@1, @2, @{@"bar":@"yarg"}]};
	b = @{@"foo":@[@1, @2, @{@"narf":@"fran"}]};
	STAssertFalse([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should not be equal: %@ v %@", a, b);
	
	a = @{@"foo":@[@1, @2, @{@"bar":@"yarg"}]};
	b = @{@"foo":@[@1, @2, @{@"bar":@"yarg"}]};
	STAssertTrue([ATUtilities dictionary:a isEqualToDictionary:b], @"Dictionaries should be equal: %@ v %@", a, b);
}

- (void)testArrayEquality {
	NSArray *a = nil;
	NSArray *b = nil;
	
	STAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[];
	STAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = nil;
	b = @[];
	STAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = @[];
	b = nil;
	STAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = @[];
	b = @[];
	STAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @3];
	b = @[@1, @2, @3];
	STAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @"foo"];
	b = @[@1, @2, @3];
	STAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @[@1, @2, @3]];
	b = @[@1, @2, @[@1, @2, @3]];
	STAssertTrue([ATUtilities array:a isEqualToArray:b], @"Arrays should be equal: %@ v %@", a, b);
	
	a = @[@1, @2, @[@1, @2, @{}]];
	b = @[@1, @2, @[@1, @2, @3]];
	STAssertFalse([ATUtilities array:a isEqualToArray:b], @"Arrays should not be equal: %@ v %@", a, b);
}

- (void)testEmailValidation {
	STAssertTrue([ATUtilities emailAddressIsValid:@"andrew@example.com"], @"Should be valid");
	STAssertTrue([ATUtilities emailAddressIsValid:@" andrew+spam@foo.md "], @"Should be valid");
	STAssertTrue([ATUtilities emailAddressIsValid:@"a_blah@a.co.uk"], @"Should be valid");
	STAssertTrue([ATUtilities emailAddressIsValid:@"☃@☃.net"], @"Snowman! Valid!");
	STAssertTrue([ATUtilities emailAddressIsValid:@"andrew@example.com"], @"Should be valid");
//	STAssertTrue([ATUtilities emailAddressIsValid:@" foo@bar.com yarg@blah.com"], @"May as well accept multiple");
//	STAssertTrue([ATUtilities emailAddressIsValid:@"Andrew Wooster <andrew@example.com>"], @"Accept contact emails");
	STAssertTrue([ATUtilities emailAddressIsValid:@"foo/bar=blah@example.com"], @"Accept department emails");
	STAssertTrue([ATUtilities emailAddressIsValid:@"!hi!%blah@example.com"], @"Should be valid");
	STAssertTrue([ATUtilities emailAddressIsValid:@"m@example.com"], @"Should be valid");
	
	STAssertFalse([ATUtilities emailAddressIsValid:@"blah"], @"Shouldn't be valid");
//	STAssertFalse([ATUtilities emailAddressIsValid:@"andrew@example,com"], @"Shouldn't be valid");
	STAssertFalse([ATUtilities emailAddressIsValid:@""], @"Shouldn't be valid");
	STAssertFalse([ATUtilities emailAddressIsValid:@"@"], @"Shouldn't be valid");
	STAssertFalse([ATUtilities emailAddressIsValid:@".com"], @"Shouldn't be valid");
	STAssertFalse([ATUtilities emailAddressIsValid:@"\n"], @"Shouldn't be valid");
//	STAssertFalse([ATUtilities emailAddressIsValid:@"foo@yarg"], @"Shouldn't be valid");
}
@end
