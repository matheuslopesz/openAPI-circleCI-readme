
require 'swagger_helper'

# Descrevemos qual API estamos documentando
describe 'Posts API', type: :request do

  # Definimos o caminho (endpoint)
  path '/posts' do

    # Definimos a operação GET para este caminho
    get 'Lista todos os posts' do
      # 'tags' agrupam operações na UI da documentação
      tags 'Posts'
      # 'produces' informa o formato da resposta
      produces 'application/json'

      # Descrevemos uma resposta esperada (HTTP 200 OK)
      response '200', 'sucesso' do
        # 'schema' descreve a estrutura da resposta
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   title: { type: :string },
                   body: { type: :string },
                   created_at: { type: :string, format: 'date-time' },
                   updated_at: { type: :string, format: 'date-time' }
                 },
                 required: [ 'id', 'title', 'body' ]
               }
        
        # 'run_test!' é o comando mágico que executa um teste real
        # para garantir que a documentação corresponde à realidade.
        run_test!
      end
    end

    # Definimos a operação POST para este caminho
    post 'Cria um post' do
      tags 'Posts'
      # 'consumes' informa o formato dos dados que a API espera receber
      consumes 'application/json'
      produces 'application/json'

      # 'parameter' descreve um parâmetro que a requisição deve ter.
      # Neste caso, o corpo (body) da requisição.
      parameter name: :post_params, in: :body, schema: {
        type: :object,
        properties: {
          title: { type: :string },
          body: { type: :string }
        },
        required: [ 'title', 'body' ]
      }



      # Descrevemos uma resposta de erro (HTTP 422 Unprocessable Entity)
      response '422', 'parâmetros inválidos' do
        # Exemplo de dados que causariam um erro (título faltando)
        let(:post_params) { { body: 'Corpo sem título.' } }
        run_test!
      end
    end
  end
end
