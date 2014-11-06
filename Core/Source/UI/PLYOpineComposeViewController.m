//
//  DTOpineComposeViewController.m
//  HungryScanner
//
//  Created by Oliver Drobnik on 23/10/14.
//  Copyright (c) 2014 Product Layer. All rights reserved.
//

#import "PLYOpineComposeViewController.h"
#import <ProductLayer/ProductLayer.h>

@interface PLYOpineComposeViewController () <UITextViewDelegate>

@end

@implementation PLYOpineComposeViewController
{
	UITextView *_textView;
	
	UIBarButtonItem *_saveButtonItem;
	UIBarButtonItem *_cancelButtonItem;
	
	NSString *_text;
	NSString *_language;
}

- (instancetype)initWithOpine:(PLYOpine *)opine
{
	self = [super init];
	
	if (self)
	{
		_text = opine.text;
		_language = opine.language;
	}
	
	return self;
}


- (void)loadView
{
	_textView = [[UITextView alloc] initWithFrame:CGRectZero];
	_textView.delegate = self;
	_textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	self.view = _textView;
	
	self.navigationItem.title = @"Your Opinion";
	
	UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelItem;
	
	_saveButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
	self.navigationItem.rightBarButtonItem = _saveButtonItem;
	
	// default language is current system language
	if (!_language)
	{
		_language = [[NSLocale preferredLanguages] objectAtIndex:0];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	_textView.text = _text;
	[self _updateButtonState];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[_textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[_textView resignFirstResponder];
}

#pragma mark - Helpers

- (void)_updateButtonState
{
	_saveButtonItem.enabled = [_textView.text length]>0;
}

- (void)_updateLanguage
{
	UITextInputMode *inputMode = [_textView textInputMode];
	NSString *lang = inputMode.primaryLanguage;
	
	if (!lang)
	{
		return;
	}
	
	NSRange range = [lang rangeOfString:@"-"];
	
	if (range.location != NSNotFound)
	{
		lang = [lang substringToIndex:range.location];
	}
	
	_language = lang;
}

#pragma mark - Actions

- (void)cancel:(id)sender
{
	if ([_delegate respondsToSelector:@selector(opineComposeViewControllerDidCancel:)])
	{
		[_delegate opineComposeViewControllerDidCancel:self];
	}
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)save:(id)sender
{
	PLYOpine *opine = nil;
 
	// return nil if there is no text
	if ([_textView.text length])
	{
		opine = [[PLYOpine alloc] init];
		opine.text = _textView.text;
		opine.language = _language;
	}
	
	if ([_delegate respondsToSelector:@selector(opineComposeViewController:didFinishWithOpine:)])
	{
		[_delegate opineComposeViewController:self didFinishWithOpine:opine];
	}
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
	[self _updateButtonState];
	[self _updateLanguage];
}

#pragma mark - Public Interface

- (NSString *)opineText
{
	return _textView.text;
}

- (void)setOpineText:(NSString *)opineText
{
	if (!self.isViewLoaded)
	{
		[self loadView];
	}
	
	_textView.text = opineText;
}

- (void)setOpine:(PLYOpine *)opine
{
	_text = opine.text;
	_language = opine.language;
}

@end
