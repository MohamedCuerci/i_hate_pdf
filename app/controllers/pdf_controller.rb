require 'zip'
class PdfController < ApplicationController
  ALLOWED_ACTIONS = %w[split merge compress convert]

  def new
    @action_type = params[:action_type] # Pega o tipo de ação da URL
    unless ALLOWED_ACTIONS.include?(@action_type)
      redirect_to root_path, alert: 'Ação inválida'
    end
  end

  def create
    if params[:pdf].present?
      begin
        @original_filename = params[:pdf].original_filename

        temp_dir = Rails.root.join('tmp', 'pdf_processing') # <Pathname:/home/cuerci/projetos/project_rails/adm_arquivos/i_hate_pdf/tmp/pdf_processing>
        FileUtils.mkdir_p(temp_dir) unless Dir.exist?(temp_dir) # cria i_hate_pdf/tmp/pdf_processing"

        # input_pdf_path = temp_dir.join("input_#{SecureRandom.uuid}.pdf") # coloca um nome para o pdf anexado na pasta "pdf_processing"
        input_pdf_path = temp_dir.join(@original_filename) # coloca um nome para o pdf anexado na pasta "pdf_processing"

        File.binwrite(input_pdf_path, params[:pdf].read)
        # "File.binwrite" é usado em vez de "File.write" para garantir que o arquivo seja salvo corretamente no formato binário, sem alterações ou perdas de dados, como a conversão de caracteres.

        case params[:action_type]
        when 'split'
          @output_filename = split_pdf(input_pdf_path, @original_filename)

          send_file(@output_filename, type: "application/zip", disposition: "attachment", filename: "iHatePdf.zip", stream: false)
          # return
        when 'merge'
          @output_filename = merge_pdf(input_pdf_path)
        when 'compress'
          @output_filename = compress_pdf(input_pdf_path)

          # Armazena os parâmetros na sessão
          # deveria mudar para session[:pdf] =
          # dessa forma seria algo generico reaproveitado em todas as funções
          session[:compressed_pdf] = {
            action: "compressed",
            file_path: @output_filename,
            filename: "#{@original_filename.gsub('.pdf', '_compressed.pdf')}"
          }

          redirect_to download_path # (file_path: @output_filename, filename: "#{@original_filename.gsub('.pdf', '_compressed.pdf')}")
        when 'convert'
          # output = convert_pdf(input_pdf_path, params[:format])
        end

        
        # redirect_to download_pdf_path, notice: 'PDF processado com sucesso!'
      ensure
        # garante q sempre seja deletado, embroa isso possa quebrar em alguns casos
        # add if por garantia
        FileUtils.rm_f(input_pdf_path) if input_pdf_path && File.exist?(input_pdf_path)
        # FileUtils.rm_f(@output_filename) if @output_filename && File.exist?(@output_filename)
      end
    else
      redirect_to new_pdf_path, alert: 'Por favor, selecione um arquivo PDF.'
    end
  end

  # rota pro download
  def download_pdf
    compressed_pdf = session[:compressed_pdf]
  
    if compressed_pdf
      send_file(compressed_pdf["file_path"], filename: compressed_pdf["filename"], type: "application/pdf")
  
      # Limpa a sessão após o envio do arquivo
      # session.delete(:compressed_pdf)
    else
      # inves de ir pro root apenas mostrar a msg
      redirect_to root_path, alert: "Arquivo não encontrado."
    end
  end
  

  def download
    # Recupera os parâmetros da sessão
    # compressed_pdf = session.delete(:compressed_pdf)
    compressed_pdf = session[:compressed_pdf]
  
    if compressed_pdf
      @file_path = compressed_pdf[:file_path]
      @filename = compressed_pdf[:filename]
    else
      # inves de ir pro root apenas mostrar a msg
      redirect_to root_path, alert: "Nenhum arquivo encontrado para download."
    end
  end

  private

  def split_pdf(input_pdf_path, name)
    output_dir = Rails.root.join('tmp', 'paginas_pdf', SecureRandom.uuid) # i_hate_pdf/tmp/paginas_pdf

    FileUtils.mkdir_p(output_dir) unless Dir.exist?(output_dir) # cria i_hate_pdf/tmp/pdf_processing

    pdf = CombinePDF.load(input_pdf_path)
    pdf.pages.each_with_index do |page, index|
      single_page_pdf = CombinePDF.new
      single_page_pdf << page
      single_page_pdf.save(File.join(output_dir, "#{name}_#{index + 1}.pdf"))
    end
  
    # Retorna o caminho para o arquivo zip criado
    create_zip_of_pdf_folder(output_dir)
  end

  def create_zip_of_pdf_folder(folder_path)
    # Criar uma pasta única dentro de 'tmp/pdf_pages_folder'
    output_dir = Rails.root.join('tmp', 'pdf_pages_folder', SecureRandom.uuid)
    FileUtils.mkdir_p(output_dir)
  
    # Caminho para o arquivo zip dentro da pasta única
    zip_file_path = output_dir.join('pdf_folder.zip')
  
    Zip::File.open(zip_file_path, Zip::File::CREATE) do |zipfile|
      Dir[File.join(folder_path, '**', '**')].each do |file|
        zipfile.add(File.basename(file), file) if File.file?(file)
      end
    end
  
    zip_file_path
  end
  
  def merge_pdf(input_pdf)
  end

  def compress_pdf(input_path)
    output_path = input_path.sub('.pdf', '_compressed.pdf')
    
    settings = [
      "-sDEVICE=pdfwrite",
      "-dCompatibilityLevel=1.4",
      "-dPDFSETTINGS=/screen",
      "-dNOPAUSE",
      "-dQUIET",
      "-dBATCH",
      "-sOutputFile=#{output_path}",
      input_path
    ]
    
    # /screen: menor qualidade, alta compressão.
    # /ebook: qualidade média, boa compressão.
    # /printer: qualidade alta, compressão moderada.
    # /prepress: qualidade mais alta, compressão mínima.

    system("gs #{settings.join(' ')}")
    output_path
  end
end
