describe('Api', function() {
  var api = TimeCrowd.api;

  describe('#constructor', function() {
    it('initializes instance variables', function() {
      expect(api.baseUrl).toEqual(TimeCrowd.keys.baseUrl);
      expect(api.version).toEqual('/api/v1');
    });
  })

  describe('#getAuthCode', function() {
    var value;

    beforeEach(function(done) {
      api.getAuthCode().then(function(code) {
        value = code;
        done();
      });
    });

    it('gets auth code', function(done) {
      expect(value).not.toBeNull();
      done();
    });
  });

  describe('#getAuthToken', function() {
    var value;

    beforeEach(function(done) {
      TimeCrowd.api.getAuthCode()
        .then(TimeCrowd.api.getAuthToken)
        .then(function(json) {
          value = json;
          done();
        });
    });

    it('gets auth token', function(done) {
      expect(value).not.toBeNull();
      done();
    });
  });

  describe('#removeAuthToken', function() {
    it('removes auth token');
  });

  describe('#request', function() {
    var value;

    beforeEach(function(done) {
      TimeCrowd.api.getAuthCode()
        .then(TimeCrowd.api.getAuthToken)
        .then(function(json) {
          TimeCrowd.api.request({ accessToken: json.access_token }, '/user', 'GET')
            .then(function(json) {
              value = json;
              done();
            });
        });
    });

    it('requests api', function(done) {
      expect(value).not.toBeNull();
      expect(value.is_anonymous).toBe(false);
      done();
    });
  });

  describe('#isExpired', function() {
    it('checks token is expired', function() {
      var now = new Date().getTime();
      var past = new Date(now - 60000).getTime();
      var future = new Date(now + 60000).getTime();

      expect(TimeCrowd.api.isExpired({ expiresAt: past })).toBe(true);
      expect(TimeCrowd.api.isExpired({ expiresAt: future })).toBe(false);
    });
  });

  describe('#saveAuthToken', function() {
    it('saves auth token');
  });
});

