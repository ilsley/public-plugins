package EnsEMBL::Web::Component::Tools::Blast::GenomicSeq;

use strict;

use base qw(EnsEMBL::Web::Component::Tools::Blast::TextSequence);

sub initialize {
  my ($self, $slice, $start, $end) = @_;
  my $hub     = $self->hub;
  my $species = $self->job->job_data->{'species'};
  my $config  = {
    display_width   => $hub->param('display_width') || 60,
    species         => $species,
    sub_slice_start => $start,
    sub_slice_end   => $end,
    ambiguity       => 1,
  };
  
  for (qw(exon_display exon_ori snp_display line_numbering hsp_display title_display)) {
    $config->{$_} = $hub->param($_) unless $hub->param($_) eq 'off';
  }
  
  $config->{'slices'} = [{ slice => $slice, name => $species }];
  
  if ($config->{'line_numbering'}) {
    $config->{'end_number'} = 1;
    $config->{'number'}     = 1;
  }
  
  my ($sequence, $markup) = $self->get_sequence_data($config->{'slices'}, $config);
  
  $self->markup_hsp($sequence, $markup, $config)       if $config->{'hsp_display'};
  $self->markup_exons($sequence, $markup, $config)     if $config->{'exon_display'};
  $self->markup_variation($sequence, $markup, $config) if $config->{'snp_display'};
  $self->markup_line_numbers($sequence, $config)       if $config->{'line_numbering'};
  
  return ($sequence, $config);
}

sub get_slice {
  my $self  = shift;
  my $hub   = $self->hub;
  my $hit   = $self->hit;
  my $slice = $self->object->get_hit_genomic_slice($hit, $self->job->job_data->{'species'}, $hub->param('flank5_display'), $hub->param('flank3_display'));
  my $ori   = $hub->param('orientation');
  my $g_ori = $hit->{'gori'};
  my $q_ori = $hit->{'qori'};
  
  if (
    ($q_ori ==  1 && $g_ori ==  1 && $ori eq 'rc') ||
    ($q_ori ==  1 && $g_ori == -1 && $ori eq 'fc') ||
    ($q_ori == -1 && $g_ori ==  1 && $ori ne 'fc') ||
    ($q_ori == -1 && $g_ori == -1 && $ori ne 'rc')
  ) {
    $slice = $slice->invert;
  }

  return $slice;
}

sub get_key {
  ## @override
  ## Adds the HSP key before calling the base class's method
  my ($self, $config) = @_;
  
  return $self->SUPER::get_key($config, {
    hsp => {
      sel   => { class => 'hsp_sel',   order => 1, text => 'Location of selected alignment' },
      other => { class => 'hsp_other', order => 2, text => 'Location of other alignments'   }
    }
  });
}

1;
