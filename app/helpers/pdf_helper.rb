module PdfHelper
  def action_title_and_description(action_type)
    case action_type
    when 'split'
      { title: 'Dividir arquivo PDF', description: 'Selecione um intervalo de páginas, separe uma página, ou converta cada página do documento em arquivo PDF independente.' }
    when 'merge'
      { title: 'Juntar arquivos PDF', description: 'Combine múltiplos arquivos PDF em um único documento.' }
    when 'compress'
      { title: 'Comprimir arquivo PDF', description: 'Diminua o tamanho do seu arquivo PDF, mantendo a melhor qualidade possível. Otimize seus arquivos PDF.' }
    when 'convert'
      { title: 'Converter PDF', description: 'Converta seu PDF para outros formatos.' }
    else
      { title: '', description: '' }
    end
  end
end
