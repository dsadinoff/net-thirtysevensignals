# $Id$

=head1 NAME

Net::Backpack - Perl extension for interfacing with Backpack

=head1 SYNOPSIS

  use Net::Backpack;

  my $bp = Net::Backpack(user  => $your_backpack_username,
                         token => $your_backpack_api_token);

  # Fill out a Perl data structure with information about
  # your Backspace pages.
  my $pages = $bp->list_all_pages;

  # Alternatively get the same information in XML format
  # my $pages = $bp->list_all_pages(xml => 1);

  # Create a new page
  my $page = $bp->create_page(title => 'A test page',
                              description => 'Created with the Backpack API');

  # Get the id of the new page
  my $page_id = $page->{page}{id};

  # Get details of the new page (in XML format)
  my $page_xml = $bp->show_page(id => $page->{page}{id});

  # Rename the page
  $bp->update_title(id => $page_id,
                    title => 'A new title');

  # Change the body
  $bp->update_description(id => $page_id,
                          description => 'Something new');

  # Remove the page
  $bp->destroy_page(id => $page_id);

=head1 DESCRIPTION

Net::Backpack provides a thin Perl wrapper around the Backpack API
(L<http://backpackit.com/api/>). Currently it only implements the
parts of the API that manipulate Backpack pages. Future releases
will increase the coverage.

=head2 Getting Started

In order to use the Backpack API, you'll need to have a Backpack
API token. And in order to get one of those, you'll need a Backpack
account. But then again, the API will be pretty useless to you if
you don't have a Backpack account to manipulate with it.

You can get a Backpack account from L<http://backbackit.com/signup>.

=head2 Backback API

The Backpack API is based on XML over HTTP. You send an XML message
over HTTP to the Backpack server and the server sends a response to
you which is also in XML. The format of the various XML requests and
responses are defined at L<http://backpackit.com/api>.

This module removes the need to deal with any XML. You create an
object to talk to the Backpack server and call methods on that object
to manipulate your Backpage pages. The values returned from Backpack
are converted to Perl data structures before being handed back to
you (although it is also possible to get back the raw XML).

=cut

package Net::Backpack;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use HTTP::Request;
use XML::Simple;

our $VERSION = '0.02';

my %data = (
	    'list_all_pages' =>
	    {
	     url => '/ws/pages/all',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'create_page' =>
	    {
	     url => '/ws/pages/new',
	     req => '<request>
  <token>[S:token]</token>
  <page>
    <title>[P:title]</title>
    <description>[P:description]</description>
  </page>
</request>'
	    },
	    'show_page' =>
	    {
	     url => '/ws/page/[P:id]',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	     },
	    'destroy_page' =>
	    {
	     url => '/ws/page/[P:id]/destroy',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	    'update_title' =>
	    {
	     url => '/ws/page/[P:id]/update_title',
	     req => '<request>
  <token>[S:token]</token>
  <page><title>[P:title]</title></page>
</request>'
	    },
	    update_body =>
	    {
	     url => '/ws/page/[P:id]/update_body',
	     req => '<request>
  <token>[S:token]</token>
  <page><description>[P:description]</description></page>
</request>'
	    },
	    'duplicate_page' =>
	    {
	     url => '/ws/page/[P:id]/duplicate',
	     req => '<request>
  <token>[S:token]</token>
</request>'
	    },
	   );

=head1 METHODS

=head2 $bp = Net::Backpack->new(token => $token, user => $user);

Creates a new Net::Backpack object. All communication with the
Backpack server is made through this object.

Takes two mandatory arguments, your Backpack API token and your
Backpack username. Returns the new Net:Backpack object.

=cut

sub new {
  my $class = shift;
  my %params = @_;

  my $self;
  $self->{token} = $params{token}
    || croak "No Backpack API token passed Net::Backpack::new\n";
  $self->{user}  = $params{user}
    || croak "No Backpack API user passed Net::Backpack::new\n";

  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->env_proxy;
  $self->{ua}->default_header('X-POST-DATA-FORMAT' => 'xml');

  $self->{base_url} = "http://$self->{user}.backpackit.com";

  return bless $self, $class;
}

=head2 $pages = list_all_pages([xml => 1]);

Get a list of all of your Backpack pages. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw
XML as returned by the Backpack server.

=cut

sub list_all_pages {
  my $self = shift;
  my %params = @_;

  my $req_data = $data{list_all_pages};
  my $url = $self->{base_url} . $req_data->{url};

  my $req = HTTP::Request->new('POST', $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $page = create_page(title => $title, [description => $desc, xml => 1]);

Create a new Backpack page with the given title and (optional)
description. Returns a Perl data structure unless the C<xml> parameter is
true, in which case it returns the raw XML as returned by the Backpack server.

=cut

sub create_page {
  my $self = shift;
  my %params = @_;

  croak 'No title for new page' unless $params{title};
  $params{description} ||= '';

  my $req_data = $data{create_page};
  my $url   = $self->{base_url} . $req_data->{url};

  my $req   = HTTP::Request->new(POST => $url);
  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = show_page(id => $id, [xml => 1]);

Get details of the Backpack page with the given id. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Backpack server.

=cut

sub show_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{show_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = delete_page(id => $id, [xml => 1]);

Delete the Backpack page with the given id. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw XML
as returned by the Backpack server.

=cut

sub destroy_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{destroy_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = update_title(id => $id, title => $title, [xml => 1]);

Update the title of the given Backpack page. Returns a Perl data structure
unless the C<xml> parameter is true, in which case it returns the raw XML 
as returned by the Backpack server.

=cut

sub update_title {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};
  croak 'No title' unless $params{title};

  my $req_data = $data{update_title};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);

  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $rc = update_body(id => $id, description => $desc, [xml => 1]);

Update the description of the given Backpack page. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Backpack server.

=cut

sub update_body {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};
  croak 'No description' unless defined $params{description};

  my $req_data = $data{update_body};
  my $url   = $self->{base_url} .$self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

=head2 $page = duplicate_page(id => $id, [xml => 1]);

Create a duplicate of the given Backpack page. Returns a Perl data
structure unless the C<xml> parameter is true, in which case it returns the
raw XML as returned by the Backpack server.

=cut

sub duplicate_page {
  my $self = shift;
  my %params = @_;

  croak 'No id' unless $params{id};

  my $req_data = $data{duplicate_page};
  my $url   = $self->{base_url} . $self->_expand($req_data->{url}, %params);
  my $req   = HTTP::Request->new(POST => $url);

  $req->content($self->_expand($req_data->{req}, %params));

  return $self->_call(%params, req => $req);
}

sub _call {
  my $self = shift;
  my %params = @_;

  my $resp = $self->{ua}->request($params{req});
  my $xml = $resp->content;

  if ($params{xml}) {
    return $xml;
  } else {
    my $data = XMLin($xml);
    return $data;
  }
}

sub _expand {
  my $self = shift;
  my $string = shift;
  my %params = @_;

  $string =~ s/\[S:(\w+)]/$self->{$1}/g;
  $string =~ s/\[P:(\w+)]/$params{$1}/g;

  return $string;
}

=head1 TO DO

=over 4

=item *

Improve documentation (I know, it's shameful)

=item *

Implement the rest of the API

=item *

More tests

=back

=head1 AUTHOR

Dave Cross E<lt>dave@dave@dave.org.ukE<gt>

Please feel free to email me to tell me how you are using the module.

=head1 BUGS

Please report bugs by email to E<lt>bug-Net-Backpack@rt.cpan.orgE<gt>.

=head1 COPYRIGHT

Copyright (c) 2005, Dave Cross.  All Rights Reserved.

This script is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<http://backpackit.com/>, L<http://backpackit.com/api>

=cut

1;
__END__
