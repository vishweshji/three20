#import "Three20/TTImageView.h"
#import "Three20/TTURLResponse.h"

//////////////////////////////////////////////////////////////////////////////////////////////////

@implementation TTImageView

@synthesize delegate = _delegate, url = _url, defaultImage = _defaultImage,
  autoresizesToImage = _autoresizesToImage;

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _delegate = nil;
    _request = nil;
    _url = nil;
    _defaultImage = nil;
    _autoresizesToImage = NO;
  }
  return self;
}

- (void)dealloc {
  _delegate = nil;
  self.url = nil;
  [_request release];
  [_defaultImage release];
  [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// UIImageView

- (void)setImage:(UIImage*)image {
  [super setImage:image];

  CGRect frame = self.frame;
  if (_autoresizesToImage) {
    self.frame = CGRectMake(frame.origin.x, frame.origin.y, image.size.width, image.size.height);
  } else {
    if (!frame.size.width && !frame.size.height) {
      self.frame = CGRectMake(frame.origin.x, frame.origin.y, image.size.width, image.size.height);
    } else if (frame.size.width && !frame.size.height) {
      self.frame = CGRectMake(frame.origin.x, frame.origin.y,
        frame.size.width, floor((image.size.height/image.size.width) * frame.size.width));
    } else if (frame.size.height && !frame.size.width) {
      self.frame = CGRectMake(frame.origin.x, frame.origin.y,
        floor((image.size.width/image.size.height) * frame.size.height), frame.size.height);
    }
  }

  if (!_defaultImage || image != _defaultImage) {
    [_delegate imageView:self loaded:image];
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////
// TTURLRequestDelegate

- (void)requestLoading:(TTURLRequest*)request {
  _request = [request retain];
  
  if ([_delegate respondsToSelector:@selector(imageViewLoading:)]) {
    [_delegate imageViewLoading:self];
  }
}

- (void)requestLoaded:(TTURLRequest*)request {
  TTURLImageResponse* response = request.response;
  self.image = response.image;
  
  [_request release];
  _request = nil;
}

- (void)request:(TTURLRequest*)request didFailWithError:(NSError*)error {
  [_request release];
  _request = nil;

  if ([_delegate respondsToSelector:@selector(imageView:loadDidFailWithError:)]) {
    [_delegate imageView:self loadDidFailWithError:error];
  }
}

- (void)requestCancelled:(TTURLRequest*)request {
  [_request release];
  _request = nil;

  if ([_delegate respondsToSelector:@selector(imageView:loadDidFailWithError:)]) {
    [_delegate imageView:self loadDidFailWithError:nil];
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setUrl:(NSString*)url {
  if (self.image && _url && [url isEqualToString:_url])
    return;
  
  [self stopLoading];
  [_url release];
  _url = [url retain];
  
  if (!_url || !_url.length) {
    if (self.image != _defaultImage) {
      self.image = _defaultImage;
    }
  } else {
    [self reload];
  }
}

- (BOOL)loading {
  return !!_request;
}

- (void)reload {
  if (_request)
    return;
  
  TTURLRequest* request = [TTURLRequest requestWithURL:_url delegate:self];
  request.response = [[[TTURLImageResponse alloc] init] autorelease];
  if (_url && ![request send]) {
    // Put the default image in place while waiting for the request to load
    if (_defaultImage && self.image != _defaultImage) {
      self.image = _defaultImage;
    }
  }
}

- (void)stopLoading {
  [_request cancel];
}

@end
