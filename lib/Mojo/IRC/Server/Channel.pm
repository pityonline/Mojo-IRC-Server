package Mojo::IRC::Server::Channel;
use Mojo::IRC::Server::Base 'Mojo::IRC::Server::Object';
use List::Util qw(first);
has 'name';
has id      => sub {lc $_[0]->name};
has topic   => sub {"欢迎来到 " . $_[0]->name};
has ctime   => sub {time()};
has mode    => 'i';
has user    => sub {[]};

sub count {
    my $s = shift;
    0+@{$s->user};
}
sub add_user{
    my $s = shift;
    my $uid = ref($_[0]) eq "Mojo::IRC::Server::User"?$_[0]->id:$_[0];
    push @{$s->user},$uid if not $s->is_has_user($uid); 
}
sub remove_user{
    my $s = shift;
    my $uid = ref($_[0]) eq "Mojo::IRC::Server::User"?$_[0]->id:$_[0];
    for(my $i=0;$i<@{$s->user};$i++){
        if($uid eq $s->user->[$i]){
            splice @{$s->user},$i,1;
            if(@{$s->user} == 0){
                $s->{_server}->remove_channel($s);
            }
            return;
        }
    }
}
sub is_has_user{
    my $s = shift;
    my $uid = ref($_[0]) eq "Mojo::IRC::Server::User"?$_[0]->id:$_[0];
    if(defined $uid){
        return (first {$uid eq $_} @{$s->user})?1:0;
    }
    else{
        return 0+@{$s->user};
    }

}
sub set_topic{
    my $s = shift;
    my $user = shift;
    my $topic = shift;
    $s->topic($topic);
    $user->broadcast($s->ident,"TOPIC",$s->name,$topic); 
    $s->info($s->name . " 主题设置为: " . $s->topic);
}
sub set_mode{
    my $s = shift;
    my $user = shift;
    my $mode = shift;
    $mode  = "+" . $mode if (substr($mode,0,1) ne '+' and substr($mode,0,1) ne '-');
    my %mode = map {$_=>1} split //,$s->mode;
    if(substr($mode,0,1) eq "+"){
        $mode{$_}=1 for  split //,substr($mode,1,);
    }
    elsif(substr($mode,0,1) eq "-"){
        delete $mode{$_} for  split //,substr($mode,1,);
    }
    else{
        %mode = ();
        $mode{$_}=1 for  split //,$mode;
    }
    $s->mode(join "",keys %mode);
    $user->broadcast($s->servername,"324",$user->nick,$s->name,$mode); 
    $s->info("[" . $s->name . "] 模式设置为: " . $s->mode);
}

sub users{
    my $s = shift;
    my @users = ();
    for my $uid (@{$s->user}){
        my $user = $s->search_user(id=>$uid);
        push @users ,$user if defined $user;
    }
    return @users;
}

1;