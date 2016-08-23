require_relative '../test_helper'

class TestBindIntegration < LDAPIntegrationTestCase
  def test_bind_success
    assert @ldap.bind(method: :simple, username: "uid=user1,ou=People,dc=rubyldap,dc=com", password: "passworD1"), @ldap.get_operation_result.inspect
  end

  def test_bind_timeout
    @ldap.port = 8389
    error = assert_raise Net::LDAP::Error do
      @ldap.bind(method: :simple, username: "uid=user1,ou=People,dc=rubyldap,dc=com", password: "passworD1")
    end
    msgs = ['Operation timed out - user specified timeout',
            'Connection timed out - user specified timeout']
    assert_send([msgs, :include?, error.message])
  end

  def test_bind_anonymous_fail
    refute @ldap.bind(method: :simple, username: "uid=user1,ou=People,dc=rubyldap,dc=com", password: ""), @ldap.get_operation_result.inspect

    result = @ldap.get_operation_result
    assert_equal Net::LDAP::ResultCodeUnwillingToPerform, result.code
    assert_equal Net::LDAP::ResultStrings[Net::LDAP::ResultCodeUnwillingToPerform], result.message
    assert_equal "unauthenticated bind (DN with no password) disallowed",
      result.error_message
    assert_equal "", result.matched_dn
  end

  def test_bind_fail
    refute @ldap.bind(method: :simple, username: "uid=user1,ou=People,dc=rubyldap,dc=com", password: "not my password"), @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_cafile
    tls_options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.merge(:ca_file => CA_FILE)
    @ldap.encryption(method: :start_tls, tls_options: tls_options)
    assert @ldap.bind(method: :simple, username: "uid=user1,ou=People,dc=rubyldap,dc=com", password: "passworD1"), @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_verify_none
    @ldap.host = '127.0.0.1'
    @ldap.port = 9389
    tls_options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.merge(
      :verify_mode => OpenSSL::SSL::VERIFY_NONE,
    )
    @ldap.encryption(method: :start_tls, tls_options: tls_options)
    assert @ldap.bind(method: :simple, username: "uid=user1,ou=People,dc=rubyldap,dc=com", password: "passworD1"), @ldap.get_operation_result.inspect
  end

  def test_bind_tls_with_bad_hostname
    @ldap.host = '127.0.0.1'
    @ldap.port = 9389
    tls_options = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS.merge(
      :verify_mode => OpenSSL::SSL::VERIFY_PEER,
      :ca_file     => CA_FILE,
    )
    @ldap.encryption(method: :start_tls, tls_options: tls_options)
    error = assert_raise Net::LDAP::Error do
      @ldap.bind(method: :simple,
                 username: "uid=user1,ou=People,dc=rubyldap,dc=com",
                 password: "passworD1")
    end
    assert_equal(
      "hostname \"#{@ldap.host}\" does not match the server certificate",
      error.message,
    )
  end
end
